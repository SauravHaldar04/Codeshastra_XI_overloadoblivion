import cv2
import numpy as np
import torch
from PIL import Image
from ultralytics import SAM
from transformers import CLIPProcessor, CLIPModel
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import networkx as nx
import os
import time
import json
from scipy.spatial import distance
from datetime import datetime
import gc  # For garbage collection to help with memory management

def custom_json_encoder(obj):
    """
    Custom JSON encoder to handle non-serializable objects.
    
    Args:
        obj: Object to serialize
        
    Returns:
        JSON serializable version of the object
    """
    if isinstance(obj, np.integer):
        return int(obj)
    elif isinstance(obj, np.floating):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    elif hasattr(obj, 'item'):
        return obj.item()  # Works for torch tensors and numpy scalars
    elif isinstance(obj, tuple):
        return list(obj)
    return str(obj)

def ensure_models_directory():
    """
    Ensure the models directory exists.
    
    Returns:
        str: Path to the models directory
    """
    models_dir = "models"
    os.makedirs(models_dir, exist_ok=True)
    return models_dir

def release_memory():
    """
    Release memory to help with CUDA out of memory errors.
    """
    # Force garbage collection
    gc.collect()
    
    # If CUDA is available, empty the cache
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        
    print("Memory released.")

def segment_and_label_image(image_path, class_list, confidence_threshold=0.35, area_threshold=500):
    """
    Segment an image using Ultralytics SAM and label segments using CLIP similarity with improved accuracy.
    
    Args:
        image_path (str): Path to the input image
        class_list (list): List of class names to compare against
        confidence_threshold (float): Minimum confidence score to accept a classification
        area_threshold (int): Minimum pixel area for a segment to be considered
        
    Returns:
        dict: Dictionary with segmentation results and labels
    """
    # Ensure models directory exists
    models_dir = ensure_models_directory()
    
    try:
        # Load and initialize models
        print("Loading models...")
        sam_model_path = os.path.join(models_dir, 'sam_b.pt')
        
        # Check if model exists in models directory, otherwise download to that location
        if not os.path.exists(sam_model_path):
            print(f"Downloading SAM model to {sam_model_path}...")
            sam_model = SAM('sam_b.pt')
            # Save the model to the models directory if possible
            if hasattr(sam_model, 'save'):
                sam_model.save(sam_model_path)
        else:
            print(f"Loading SAM model from {sam_model_path}...")
            sam_model = SAM(sam_model_path)
        
        # Set up CLIP model with caching to models directory
        clip_cache_dir = os.path.join(models_dir, 'clip_cache')
        os.makedirs(clip_cache_dir, exist_ok=True)
        
        clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32", 
                                              cache_dir=clip_cache_dir)
        clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32",
                                                     cache_dir=clip_cache_dir)
        
        # Set device
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        print(f"Using device: {device}")
        
        clip_model = clip_model.to(device)
        
        # Load and prepare the image
        original_image = cv2.imread(image_path)
        original_image_rgb = cv2.cvtColor(original_image, cv2.COLOR_BGR2RGB)
        
        # Get image dimensions
        image_height, image_width = original_image_rgb.shape[:2]
        total_image_area = image_height * image_width
        
        # Enhanced class descriptions for better classification
        enhanced_class_descriptions = [f"a photo of a {cls}" for cls in class_list]
        # Add "not a" class to handle background or unrecognized objects
        enhanced_class_descriptions.append("not a recognizable object")
        
        # Perform segmentation using SAM
        print(f"Segmenting image: {image_path}...")
        
        try:
            # Use with smaller batch size if available to save memory
            results = sam_model(original_image_rgb, device=device)
        except RuntimeError as e:
            if 'CUDA out of memory' in str(e):
                print("CUDA out of memory. Releasing memory and trying with CPU...")
                release_memory()
                device = torch.device('cpu')
                clip_model = clip_model.to(device)
                results = sam_model(original_image_rgb, device=device)
            else:
                raise e
        
        # Process segmentation results
        segments = []
        labels = []
        scores = []
        label_confidences = []
        
        # Get masks from SAM results
        masks = results[0].masks.data
        
        print(f"Found {len(masks)} segments")
        
        # Process each mask
        for i, mask in enumerate(masks):
            # Convert mask to numpy array for processing
            binary_mask = mask.cpu().numpy()
            
            # Calculate mask area and coverage ratio
            mask_area = np.sum(binary_mask)
            mask_coverage = mask_area / total_image_area
            
            # Skip segments that are too small or too large
            if mask_area < area_threshold or mask_coverage > 0.9:
                continue
                
            # Apply mask to original image to extract segment
            segment_img = np.zeros_like(original_image_rgb)
            segment_img[binary_mask.astype(bool)] = original_image_rgb[binary_mask.astype(bool)]
            
            # Get bounding box for the segment
            y_indices, x_indices = np.where(binary_mask)
            if len(y_indices) == 0 or len(x_indices) == 0:
                continue
                
            x_min, x_max = np.min(x_indices), np.max(x_indices)
            y_min, y_max = np.min(y_indices), np.max(y_indices)
            
            # Only use segments of reasonable size
            if (x_max - x_min < 20) or (y_max - y_min < 20):
                continue
                
            # Calculate aspect ratio to filter out unreasonable segments
            aspect_ratio = (x_max - x_min) / (y_max - y_min) if (y_max - y_min) > 0 else 0
            if aspect_ratio > 10 or aspect_ratio < 0.1:
                continue
            
            # Calculate center of segment for scene graph
            center_x = (x_min + x_max) // 2
            center_y = (y_min + y_max) // 2
                
            # Crop the segment to its bounding box with padding
            padding = 5
            x_min_pad = max(0, x_min - padding)
            y_min_pad = max(0, y_min - padding)
            x_max_pad = min(image_width, x_max + padding)
            y_max_pad = min(image_height, y_max + padding)
            
            # Extract the padded segment
            cropped_segment = original_image_rgb[y_min_pad:y_max_pad, x_min_pad:x_max_pad]
            
            # Convert to PIL Image for CLIP
            pil_segment = Image.fromarray(cropped_segment)
            
            # Store only necessary data and convert to standard Python types to avoid serialization issues
            segments.append({
                'image': pil_segment,
                'mask': binary_mask,
                'bbox': (int(x_min), int(y_min), int(x_max), int(y_max)),
                'center': (int(center_x), int(center_y)),  # Convert to regular ints
                'area': int(mask_area),
                'coverage': float(mask_coverage)
            })
            
            # Try multiple augmentations for better classification
            print(f"Classifying segment {i+1}...")
            
            # Check for memory issues and release if needed
            if i > 0 and i % 10 == 0 and torch.cuda.is_available():
                if torch.cuda.memory_allocated() > 0.8 * torch.cuda.get_device_properties(0).total_memory:
                    print(f"Memory usage high after {i} segments. Releasing memory...")
                    release_memory()
            
            # Multiple crops to improve classification
            augmented_images = [
                pil_segment,  # Original crop
                pil_segment.resize((224, 224)),  # Resized to CLIP's preferred input size
            ]
            
            try:
                # Prepare text inputs for CLIP with enhanced descriptions
                text_inputs = clip_processor(
                    text=enhanced_class_descriptions,
                    return_tensors="pt",
                    padding=True
                ).to(device)
                
                all_similarities = []
                
                # Process each augmented image
                for aug_img in augmented_images:
                    # Prepare image input for CLIP
                    image_inputs = clip_processor(
                        images=aug_img,
                        return_tensors="pt"
                    ).to(device)
                    
                    # Get CLIP predictions
                    with torch.no_grad():
                        outputs = clip_model(**{**image_inputs, **text_inputs})
                        
                        # Calculate similarity scores
                        image_embeds = outputs.image_embeds / outputs.image_embeds.norm(dim=-1, keepdim=True)
                        text_embeds = outputs.text_embeds / outputs.text_embeds.norm(dim=-1, keepdim=True)
                        similarity = (100.0 * image_embeds @ text_embeds.T).softmax(dim=-1)
                        
                        all_similarities.append(similarity[0].cpu().numpy())
                
                # Average the similarities across augmentations
                avg_similarity = np.mean(all_similarities, axis=0)
                
                # Get top similarities
                top_indices = np.argsort(avg_similarity)[::-1][:3]  # Get top 3 predictions
                top_values = avg_similarity[top_indices]
                
                # Check if the best score is above the threshold
                best_idx = top_indices[0]
                best_score = float(top_values[0])  # Convert to regular float
                
                # If the best match is the "not a recognizable object" or below threshold, mark as unknown
                if best_idx == len(enhanced_class_descriptions) - 1 or best_score < confidence_threshold:
                    label = "unknown"
                    score = best_score
                else:
                    # Get the best class from the original class list (removing the "a photo of a" prefix)
                    label = class_list[best_idx]
                    score = best_score
                    
                    # Provide top alternatives for debugging
                    alternatives = [(class_list[idx] if idx < len(class_list) else "unknown", float(avg_similarity[idx])) 
                                   for idx in top_indices if idx < len(class_list)]
                    print(f"Top predictions for segment {i+1}: {alternatives}")
                
                labels.append(label)
                scores.append(score)
                
                # Store alternatives in native Python types for JSON serialization
                label_confidences.append({
                    'label': label,
                    'score': float(score),  # Convert to regular float
                    'alternatives': [(class_list[idx] if idx < len(class_list) else "unknown", float(avg_similarity[idx])) 
                                   for idx in top_indices[:3] if idx < len(class_list)]
                })
                
            except RuntimeError as e:
                if 'CUDA out of memory' in str(e):
                    print(f"CUDA out of memory during classification of segment {i+1}. Switching to CPU...")
                    release_memory()
                    
                    # Move model to CPU
                    device = torch.device('cpu')
                    clip_model = clip_model.to(device)
                    
                    # Retry with CPU
                    text_inputs = clip_processor(
                        text=enhanced_class_descriptions,
                        return_tensors="pt",
                        padding=True
                    ).to(device)
                    
                    all_similarities = []
                    
                    # Process each augmented image on CPU
                    for aug_img in augmented_images:
                        image_inputs = clip_processor(
                            images=aug_img,
                            return_tensors="pt"
                        ).to(device)
                        
                        with torch.no_grad():
                            outputs = clip_model(**{**image_inputs, **text_inputs})
                            image_embeds = outputs.image_embeds / outputs.image_embeds.norm(dim=-1, keepdim=True)
                            text_embeds = outputs.text_embeds / outputs.text_embeds.norm(dim=-1, keepdim=True)
                            similarity = (100.0 * image_embeds @ text_embeds.T).softmax(dim=-1)
                            all_similarities.append(similarity[0].cpu().numpy())
                    
                    # Process results as before
                    avg_similarity = np.mean(all_similarities, axis=0)
                    top_indices = np.argsort(avg_similarity)[::-1][:3]
                    top_values = avg_similarity[top_indices]
                    best_idx = top_indices[0]
                    best_score = float(top_values[0])
                    
                    if best_idx == len(enhanced_class_descriptions) - 1 or best_score < confidence_threshold:
                        label = "unknown"
                        score = best_score
                    else:
                        label = class_list[best_idx]
                        score = best_score
                    
                    labels.append(label)
                    scores.append(score)
                    label_confidences.append({
                        'label': label,
                        'score': float(score),
                        'alternatives': [(class_list[idx] if idx < len(class_list) else "unknown", float(avg_similarity[idx])) 
                                       for idx in top_indices[:3] if idx < len(class_list)]
                    })
                else:
                    raise e
        
        # Create results dictionary
        results_dict = {
            'original_image': original_image_rgb,
            'segments': segments,
            'labels': labels,
            'scores': scores,
            'confidences': label_confidences,
            'image_dimensions': (int(image_width), int(image_height))  # Convert to regular ints
        }
        
        return results_dict
        
    finally:
        # Clean up to prevent memory leaks
        release_memory()

def create_scene_graph(results, distance_threshold=150, relationship_threshold=0.3):
    """
    Create a scene graph based on object positions and their relationships.
    Ignores objects with "unknown" labels.
    
    Args:
        results (dict): Results from segment_and_label_image function
        distance_threshold (int): Maximum distance (in pixels) for objects to be considered related
        relationship_threshold (float): Threshold for determining relationship strength
        
    Returns:
        nx.Graph: NetworkX graph representing the scene
    """
    # Extract relevant data from results
    segments = results['segments']
    labels = results['labels']
    scores = results['scores']
    image_width, image_height = results['image_dimensions']
    
    # Initialize a graph
    G = nx.Graph()
    
    # Dictionary to map from original index to graph node ID (for use in the comparison code)
    index_mapping = {}
    next_node_id = 0
    
    # Add nodes (objects) to the graph, skipping unknowns
    for i, (segment, label, score) in enumerate(zip(segments, labels, scores)):
        # Skip objects labeled as "unknown"
        if label == "unknown":
            continue
            
        node_id = next_node_id
        index_mapping[i] = node_id
        next_node_id += 1
        
        center_x, center_y = segment['center']
        
        # Normalize coordinates to 0-1 range for better visualization
        norm_x = center_x / image_width
        norm_y = center_y / image_height
        
        # Add node with its attributes
        G.add_node(node_id, 
                  original_index=i,  # Store original index for reference
                  label=label, 
                  score=float(score),  # Convert to regular float 
                  pos=(float(norm_x), float(norm_y)),  # Convert to regular floats
                  center=(int(center_x), int(center_y)),  # Convert to regular ints
                  area=int(segment['area']),  # Convert to regular int
                  bbox=tuple(int(x) for x in segment['bbox']))  # Convert all to regular ints
    
    # Define spatial relationships
    def get_relationship(pos1, pos2, img_width, img_height):
        """Determine the spatial relationship between objects"""
        x1, y1 = pos1
        x2, y2 = pos2
        
        dx = x2 - x1
        dy = y2 - y1
        
        # Normalize distances
        dx_norm = dx / img_width
        dy_norm = dy / img_height
        
        # Determine horizontal relationship
        if dx_norm > 0.1:
            h_rel = "left_of"
        elif dx_norm < -0.1:
            h_rel = "right_of"
        else:
            h_rel = "aligned_with"
            
        # Determine vertical relationship
        if dy_norm > 0.1:
            v_rel = "above"
        elif dy_norm < -0.1:
            v_rel = "below"
        else:
            v_rel = "level_with"
            
        # Calculate Euclidean distance
        dist = np.sqrt(dx**2 + dy**2)
        norm_dist = dist / np.sqrt(img_width**2 + img_height**2)
        
        # Return formatted relationship and normalized distance
        rel = f"{h_rel}-{v_rel}"
        return rel, float(norm_dist)  # Convert to regular float
    
    # Add edges (relationships) to the graph
    for u in G.nodes():
        u_original = G.nodes[u]['original_index']
        pos_u = G.nodes[u]['center']
        
        for v in G.nodes():
            if u >= v:  # Avoid duplicate edges and self-loops
                continue
            
            v_original = G.nodes[v]['original_index']
            pos_v = G.nodes[v]['center']
                
            # Calculate Euclidean distance between objects
            dist = distance.euclidean(pos_u, pos_v)
            
            # Only create edges between objects that are close enough
            if dist <= distance_threshold:
                relationship, norm_dist = get_relationship(pos_u, pos_v, image_width, image_height)
                
                # Add edge with relationship data - convert all numeric values to Python native types
                G.add_edge(u, v, 
                          relationship=relationship, 
                          distance=float(dist),  # Convert to regular float
                          norm_distance=float(norm_dist),  # Convert to regular float
                          weight=float(1 - norm_dist))  # Convert to regular float
    
    # Calculate graph centrality measures to identify important objects
    try:
        centrality = nx.degree_centrality(G)
        betweenness = nx.betweenness_centrality(G)
        
        # Add centrality measures to nodes
        for node in G.nodes():
            G.nodes[node]['centrality'] = float(centrality[node])  # Convert to regular float
            G.nodes[node]['betweenness'] = float(betweenness[node])  # Convert to regular float
    except:
        # If centrality fails (e.g., for empty or near-empty graphs)
        print("Warning: Unable to calculate centrality measures. Graph may be empty or near-empty.")
        for node in G.nodes():
            G.nodes[node]['centrality'] = 0.0
            G.nodes[node]['betweenness'] = 0.0
    
    # Store the index mapping in the graph as an attribute
    G.graph['index_mapping'] = index_mapping
    
    return G

def visualize_scene_graph(results, graph, output_dir=None, show_relationships=True):
    """
    Visualize the scene graph alongside the original image.
    
    Args:
        results (dict): Results from segment_and_label_image function
        graph (nx.Graph): The scene graph to visualize
        output_dir (str): Directory to save visualization (optional)
        show_relationships (bool): Whether to show relationship labels on edges
    """
    # Skip visualization if graph is empty
    if len(graph.nodes()) == 0:
        print("Cannot visualize empty graph. No objects were detected.")
        return None
    
    original_image = results['original_image']
    segments = results['segments']
    labels = results['labels']
    
    # Get the index mapping from the graph
    index_mapping = graph.graph.get('index_mapping', {})
    
    # Create a figure with 2 subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 10))
    
    # Plot original image with labeled segments
    ax1.imshow(original_image)
    ax1.set_title('Original Image with Segmentation', fontsize=14)
    ax1.axis('off')
    
    # Define colors for visualization
    colors = plt.cm.tab20(np.linspace(0, 1, 20))
    
    # Add bounding boxes and labels for all segments
    for i, (segment, label) in enumerate(zip(segments, labels)):
        # Skip unknown labels
        if label == "unknown":
            continue
            
        # Get color based on node index if it exists in the graph
        color_idx = -1
        for node_id, original_idx in nx.get_node_attributes(graph, 'original_index').items():
            if original_idx == i:
                color_idx = node_id % len(colors)
                break
                
        if color_idx == -1:
            continue  # Skip if the segment is not in the graph
            
        color = colors[color_idx]
        
        # Get bounding box
        x_min, y_min, x_max, y_max = segment['bbox']
        
        # Add rectangle
        rect = patches.Rectangle(
            (x_min, y_min), 
            x_max - x_min, 
            y_max - y_min, 
            linewidth=2, 
            edgecolor=color, 
            facecolor='none'
        )
        ax1.add_patch(rect)
        
        # Add label and node ID
        node_id = None
        for k, v in index_mapping.items():
            if k == i:
                node_id = v
                break
                
        if node_id is not None:
            ax1.text(
                x_min, 
                y_min - 5, 
                f"{node_id}: {label}", 
                color='white', 
                fontsize=10, 
                bbox=dict(facecolor=color, alpha=0.7)
            )
        
            # Add center point
            center_x, center_y = segment['center']
            ax1.plot(center_x, center_y, 'o', color=color, markersize=8)
    
    # Plot scene graph
    ax2.set_title('Scene Graph', fontsize=14)
    ax2.axis('off')
    
    # Get node positions (normalized)
    pos = nx.get_node_attributes(graph, 'pos')
    
    # Scale positions for better visualization (flip y-axis to match image coordinates)
    scaled_pos = {node: (pos[node][0], 1 - pos[node][1]) for node in pos}
    
    # Get node labels, scores and centrality for sizing
    node_labels = nx.get_node_attributes(graph, 'label')
    node_centrality = nx.get_node_attributes(graph, 'centrality')
    
    # Calculate node sizes based on centrality (importance in the scene)
    node_sizes = [2000 * (0.5 + node_centrality[node]) for node in graph.nodes()]
    
    # Draw the graph
    nx.draw_networkx_nodes(graph, scaled_pos, ax=ax2, 
                          node_size=node_sizes,
                          node_color=[colors[i % len(colors)] for i in graph.nodes()],
                          alpha=0.8)
    
    # Add node labels
    nx.draw_networkx_labels(graph, scaled_pos, ax=ax2,
                          labels={n: f"{n}: {node_labels[n]}" for n in graph.nodes()},
                          font_size=10, font_color='black')
    
    # Draw edges with varying width based on relationship strength
    if len(graph.edges()) > 0:
        edge_weights = [graph[u][v]['weight'] * 3 for u, v in graph.edges()]
        nx.draw_networkx_edges(graph, scaled_pos, ax=ax2, 
                               width=edge_weights, 
                               alpha=0.6, 
                               edge_color='gray')
        
        # Add edge labels if requested
        if show_relationships:
            edge_labels = {(u, v): graph[u][v]['relationship'] for u, v in graph.edges()}
            nx.draw_networkx_edge_labels(graph, scaled_pos, ax=ax2,
                                       edge_labels=edge_labels,
                                       font_size=8)
    
    # Adjust layout
    plt.tight_layout()
    
    # Save if output directory is provided
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        plt.savefig(os.path.join(output_dir, 'scene_graph.png'), dpi=300, bbox_inches='tight')
    
    plt.show()
    return fig

def convert_graph_to_json(graph):
    """
    Convert a NetworkX graph to a JSON-serializable dictionary.
    
    Args:
        graph (nx.Graph): The graph to convert
        
    Returns:
        dict: JSON-serializable dictionary representing the graph
    """
    # Create a dictionary representation of the graph
    graph_data = {
        'nodes': [],
        'edges': [],
        'metadata': {
            'node_count': len(graph.nodes()),
            'edge_count': len(graph.edges()),
            'graph_density': float(nx.density(graph)),
            'timestamp': datetime.now().isoformat()
        }
    }
    
    # Process nodes
    for node, attrs in graph.nodes(data=True):
        node_data = {'id': node}
        # Convert attributes to serializable format
        for key, value in attrs.items():
            node_data[key] = custom_json_encoder(value)
        graph_data['nodes'].append(node_data)
    
    # Process edges
    for u, v, attrs in graph.edges(data=True):
        edge_data = {'source': u, 'target': v}
        # Convert attributes to serializable format
        for key, value in attrs.items():
            edge_data[key] = custom_json_encoder(value)
        graph_data['edges'].append(edge_data)
    
    return graph_data

def process_image_to_scene_graph(image_path, class_list, output_dir=None, save_visualization=True, return_json=True):
    """
    Process an image, create a scene graph, and return it in JSON format.
    
    Args:
        image_path (str): Path to the image
        class_list (list): List of class names to detect
        output_dir (str): Directory to save outputs (optional)
        save_visualization (bool): Whether to save visualization
        return_json (bool): Whether to return graph as JSON or NetworkX object
        
    Returns:
        dict or nx.Graph: Scene graph as JSON dict or NetworkX object
    """
    try:
        # Create output directory if provided
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        # Step 1: Segment and label the image
        print(f"Processing image: {image_path}")
        results = segment_and_label_image(
            image_path,
            class_list,
            confidence_threshold=0.35,
            area_threshold=500
        )
        
        # Step 2: Create scene graph
        graph = create_scene_graph(
            results,
            distance_threshold=200,
            relationship_threshold=0.3
        )
        
        # Step 3: Visualize if requested
        if save_visualization and output_dir:
            fig = visualize_scene_graph(
                results,
                graph,
                output_dir,
                show_relationships=True
            )
            plt.close(fig) if fig else None  # Close figure to save memory
        
        # Step 4: Save original results (excluding large binary data)
        if output_dir:
            # Save a simplified version of the results
            simplified_results = {
                'image_path': image_path,
                'image_dimensions': results['image_dimensions'],
                'labels': results['labels'],
                'scores': [float(score) for score in results['scores']],
                'segment_info': [{
                    'bbox': [int(x) for x in segment['bbox']], 
                    'center': [int(x) for x in segment['center']],
                    'area': int(segment['area'])
                } for segment in results['segments']]
            }
            
            with open(os.path.join(output_dir, 'scene_data.json'), 'w') as f:
                json.dump(simplified_results, f, indent=2, default=custom_json_encoder)
        
        # Step 5: Save or return the graph in JSON format
        graph_json = convert_graph_to_json(graph)
        
        if output_dir:
            with open(os.path.join(output_dir, 'scene_graph.json'), 'w') as f:
                json.dump(graph_json, f, indent=2)
        
        if return_json:
            return graph_json
        else:
            return graph, results  # Return both the graph and the results for further processing
    except Exception as e:
        print(f"Error processing image: {e}")
        import traceback
        traceback.print_exc()
        
        # Return empty structures in case of error to avoid crashing
        if return_json:
            return {
                'nodes': [], 
                'edges': [], 
                'metadata': {
                    'error': str(e),
                    'timestamp': datetime.now().isoformat()
                }
            }
        else:
            g = nx.Graph()
            g.graph['error'] = str(e)
            return g, {'error': str(e)}
    finally:
        # Always release memory
        release_memory()

# if __name__ == "__main__":
#     # Example usage
#     image_path = "before_warehouse.jpg"
    
#     class_list = [
#         "person", "cat", "dog", "car", "bicycle", 
#         "chair", "table", "bottle", "cup", "laptop",
#         "book", "phone", "keyboard", "mouse", "plant",
#         "backpack", "umbrella", "handbag", "tie", "suitcase",
#         "bag of chips", "snack bag", "food package", "food container",
#         "plastic bag", "paper bag", "box", "cardboard box", "container", "brown box"
#     ]
    
#     # Create output directory with timestamp
#     timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
#     output_dir = f"output/scene_graph_{timestamp}"
    
#     # Process image and get scene graph as JSON
#     scene_graph_json = process_image_to_scene_graph(
#         image_path,
#         class_list,
#         output_dir,
#         save_visualization=True,
#         return_json=True
#     )
    
#     print(f"Scene graph created and saved to {output_dir}")