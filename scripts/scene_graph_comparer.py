import cv2
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import networkx as nx
import os
import json
from scipy.spatial import distance
from matplotlib.colors import to_rgba
from datetime import datetime

def load_scene_graph_from_json(json_path_or_data):
    """
    Load a scene graph from a JSON file or JSON data.
    
    Args:
        json_path_or_data (str or dict): Path to JSON file or JSON data dictionary
        
    Returns:
        nx.Graph: NetworkX graph
    """
    # Load JSON data
    if isinstance(json_path_or_data, str):
        with open(json_path_or_data, 'r') as f:
            graph_data = json.load(f)
    else:
        graph_data = json_path_or_data
    
    # Create a new graph
    G = nx.Graph()
    
    # Add nodes
    for node_data in graph_data['nodes']:
        node_id = node_data.pop('id')
        
        # Convert position back to tuple if it's a list
        if 'pos' in node_data and isinstance(node_data['pos'], list):
            node_data['pos'] = tuple(node_data['pos'])
        
        # Convert center back to tuple if it's a list
        if 'center' in node_data and isinstance(node_data['center'], list):
            node_data['center'] = tuple(node_data['center'])
            
        # Convert bbox back to tuple if it's a list
        if 'bbox' in node_data and isinstance(node_data['bbox'], list):
            node_data['bbox'] = tuple(node_data['bbox'])
        
        G.add_node(node_id, **node_data)
    
    # Add edges
    for edge_data in graph_data['edges']:
        source = edge_data.pop('source')
        target = edge_data.pop('target')
        G.add_edge(source, target, **edge_data)
    
    return G

def load_image_data(json_path_or_data):
    """
    Load image data from a JSON file or JSON data.
    
    Args:
        json_path_or_data (str or dict): Path to JSON file or JSON data dictionary
        
    Returns:
        dict: Image data
    """
    # Load JSON data
    if isinstance(json_path_or_data, str):
        with open(json_path_or_data, 'r') as f:
            return json.load(f)
    else:
        return json_path_or_data

def load_image(image_path):
    """
    Load an image from file.
    
    Args:
        image_path (str): Path to the image
        
    Returns:
        numpy.ndarray: Image as an RGB numpy array
    """
    image = cv2.imread(image_path)
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

def compare_scene_graphs(before_graph, after_graph, similarity_threshold=0.7, 
                         position_weight=0.3, label_weight=0.7):
    """
    Compare two scene graphs to identify changes between before and after.
    
    Args:
        before_graph (nx.Graph): Scene graph from the before image
        after_graph (nx.Graph): Scene graph from the after image
        similarity_threshold (float): Threshold to consider objects the same across images
        position_weight (float): Weight for position similarity (0-1)
        label_weight (float): Weight for label similarity (0-1)
        
    Returns:
        dict: Dictionary containing the comparison results
    """
    # Verify weights sum to 1
    assert abs(position_weight + label_weight - 1.0) < 1e-6, "Weights must sum to 1.0"
    
    # Get node attributes
    before_labels = nx.get_node_attributes(before_graph, 'label')
    after_labels = nx.get_node_attributes(after_graph, 'label')
    before_positions = nx.get_node_attributes(before_graph, 'pos')
    after_positions = nx.get_node_attributes(after_graph, 'pos')
    
    # Get the original indices for reference
    before_original_indices = nx.get_node_attributes(before_graph, 'original_index')
    after_original_indices = nx.get_node_attributes(after_graph, 'original_index')
    
    # Create object matching between before and after
    matches = []  # [(before_id, after_id, similarity), ...]
    unmatched_before = set(before_graph.nodes())
    unmatched_after = set(after_graph.nodes())
    
    # Calculate object feature vectors (position + class)
    for before_id in before_graph.nodes():
        before_label = before_labels[before_id]
        before_pos = before_positions[before_id]
        
        best_match = None
        best_similarity = 0.0
        
        # Find potential matches in the after graph
        for after_id in after_graph.nodes():
            after_label = after_labels[after_id]
            after_pos = after_positions[after_id]
            
            # Calculate label similarity (1.0 if same, 0.0 if different)
            label_similarity = 1.0 if before_label == after_label else 0.0
            
            # Calculate position similarity (Euclidean distance, normalized)
            pos_distance = distance.euclidean(before_pos, after_pos)
            position_similarity = max(0.0, 1.0 - pos_distance)
            
            # Combined similarity (weighted average)
            combined_similarity = (label_weight * label_similarity + 
                                  position_weight * position_similarity)
            
            # Update best match if this is better
            if combined_similarity > best_similarity:
                best_similarity = combined_similarity
                best_match = after_id
        
        # If we found a match above the threshold, record it
        if best_match is not None and best_similarity >= similarity_threshold:
            matches.append((before_id, best_match, best_similarity))
            unmatched_before.discard(before_id)
            unmatched_after.discard(best_match)
    
    # Initialize change analysis dictionary
    change_analysis = {
        'appeared_objects': [],   # Objects that only exist in the after image
        'disappeared_objects': [], # Objects that only exist in the before image
        'moved_objects': [],      # Objects that changed position
        'matched_objects': [],    # Objects that match between images
        'relationship_changes': [] # Changes in relationships between objects
    }
    
    # Process disappeared objects
    for before_id in unmatched_before:
        change_analysis['disappeared_objects'].append({
            'id': before_id,
            'original_index': before_original_indices.get(before_id, None),
            'label': before_labels[before_id],
            'position': before_positions[before_id]
        })
    
    # Process appeared objects
    for after_id in unmatched_after:
        change_analysis['appeared_objects'].append({
            'id': after_id,
            'original_index': after_original_indices.get(after_id, None),
            'label': after_labels[after_id],
            'position': after_positions[after_id]
        })
    
    # Process matched objects and identify movement
    for before_id, after_id, similarity in matches:
        before_pos = before_positions[before_id]
        after_pos = after_positions[after_id]
        
        # Calculate position change
        pos_distance = distance.euclidean(before_pos, after_pos)
        
        # Record the match
        match_data = {
            'before_id': before_id,
            'after_id': after_id,
            'before_original_index': before_original_indices.get(before_id, None),
            'after_original_index': after_original_indices.get(after_id, None),
            'label': before_labels[before_id],
            'similarity': similarity,
            'position_change': pos_distance
        }
        
        # If position changed significantly, also add to moved objects
        if pos_distance > 0.05:  # Threshold for considering an object moved
            change_analysis['moved_objects'].append(match_data)
        
        change_analysis['matched_objects'].append(match_data)
    
    # Create mapping from before to after IDs
    id_mapping = {before_id: after_id for before_id, after_id, _ in matches}
    
    # Analyze relationship changes
    for before_u, before_v in before_graph.edges():
        # Skip if either node disappeared
        if before_u not in id_mapping or before_v not in id_mapping:
            continue
            
        after_u = id_mapping[before_u]
        after_v = id_mapping[before_v]
        
        # Check if the relationship still exists
        if after_graph.has_edge(after_u, after_v):
            # Get relationship data
            before_rel = before_graph[before_u][before_v]['relationship']
            after_rel = after_graph[after_u][after_v]['relationship']
            
            # If relationship changed
            if before_rel != after_rel:
                change_analysis['relationship_changes'].append({
                    'before_nodes': (before_u, before_v),
                    'after_nodes': (after_u, after_v),
                    'before_relationship': before_rel,
                    'after_relationship': after_rel,
                    'labels': (before_labels[before_u], before_labels[before_v])
                })
        else:
            # Relationship was lost
            change_analysis['relationship_changes'].append({
                'before_nodes': (before_u, before_v),
                'after_nodes': (after_u, after_v),
                'before_relationship': before_graph[before_u][before_v]['relationship'],
                'after_relationship': 'none',
                'labels': (before_labels[before_u], before_labels[before_v])
            })
    
    # Check for new relationships in after graph
    for after_u, after_v in after_graph.edges():
        # Find corresponding before nodes
        before_nodes = []
        for before_id, mapped_after_id in id_mapping.items():
            if mapped_after_id == after_u or mapped_after_id == after_v:
                before_nodes.append((before_id, mapped_after_id))
        
        # Group nodes by after_id
        node_mapping = {}
        for before_id, after_id in before_nodes:
            node_mapping[after_id] = before_id
        
        # Skip if we can't map both nodes back to before graph
        if after_u not in node_mapping or after_v not in node_mapping:
            continue
            
        before_u = node_mapping[after_u]
        before_v = node_mapping[after_v]
        
        # If this is a new relationship
        if not before_graph.has_edge(before_u, before_v):
            change_analysis['relationship_changes'].append({
                'before_nodes': (before_u, before_v),
                'after_nodes': (after_u, after_v),
                'before_relationship': 'none',
                'after_relationship': after_graph[after_u][after_v]['relationship'],
                'labels': (after_labels[after_u], after_labels[after_v])
            })
    
    # Calculate graph-level metrics
    change_analysis['metrics'] = {
        'before_object_count': len(before_graph.nodes()),
        'after_object_count': len(after_graph.nodes()),
        'appeared_count': len(change_analysis['appeared_objects']),
        'disappeared_count': len(change_analysis['disappeared_objects']),
        'moved_count': len(change_analysis['moved_objects']),
        'matched_count': len(change_analysis['matched_objects']),
        'relationship_change_count': len(change_analysis['relationship_changes']),
        'before_relationship_count': len(before_graph.edges()),
        'after_relationship_count': len(after_graph.edges()),
        'before_density': nx.density(before_graph),
        'after_density': nx.density(after_graph)
    }
    
    # Create summary text
    change_analysis['summary'] = (
        f"Scene Change Summary:\n"
        f"- {change_analysis['metrics']['appeared_count']} new objects appeared\n"
        f"- {change_analysis['metrics']['disappeared_count']} objects disappeared\n"
        f"- {change_analysis['metrics']['moved_count']} objects moved\n"
        f"- {change_analysis['metrics']['relationship_change_count']} relationships changed\n"
    )
    
    # Create mapping between before and after graphs
    change_analysis['id_mapping'] = id_mapping
    
    return change_analysis

def visualize_scene_comparison(before_image, after_image, before_graph, after_graph, 
                              change_analysis, output_dir=None):
    """
    Visualize the comparison between two scene graphs.
    
    Args:
        before_image (numpy.ndarray): Before image as RGB array
        after_image (numpy.ndarray): After image as RGB array
        before_graph (nx.Graph): Scene graph from the before image
        after_graph (nx.Graph): Scene graph from the after image
        change_analysis (dict): Results from compare_scene_graphs function
        output_dir (str): Directory to save visualization (optional)
    """
    # Create figure with 2x2 subplots
    fig, axes = plt.subplots(2, 2, figsize=(22, 16))
    plt.subplots_adjust(wspace=0.3, hspace=0.3)
    
    # Plot before image
    axes[0, 0].imshow(before_image)
    axes[0, 0].set_title('Before Image', fontsize=16)
    axes[0, 0].axis('off')
    
    # Plot after image
    axes[0, 1].imshow(after_image)
    axes[0, 1].set_title('After Image', fontsize=16)
    axes[0, 1].axis('off')
    
    # Plot before scene graph with annotations
    axes[1, 0].set_title('Before Scene Graph', fontsize=16)
    axes[1, 0].axis('off')
    
    # Get node positions for before graph
    before_pos = nx.get_node_attributes(before_graph, 'pos')
    before_labels = nx.get_node_attributes(before_graph, 'label')
    
    # Scale positions for better visualization (flip y-axis to match image coordinates)
    before_scaled_pos = {node: (before_pos[node][0], 1 - before_pos[node][1]) for node in before_pos}
    
    # Assign colors based on object status
    disappeared_nodes = [node['id'] for node in change_analysis['disappeared_objects']]
    moved_before_nodes = [match['before_id'] for match in change_analysis['moved_objects']]
    matched_before_nodes = [match['before_id'] for match in change_analysis['matched_objects']]
    
    # Define node colors for before graph
    before_node_colors = []
    for node in before_graph.nodes():
        if node in disappeared_nodes:
            before_node_colors.append('red')
        elif node in moved_before_nodes:
            before_node_colors.append('orange')
        elif node in matched_before_nodes:
            before_node_colors.append('green')
        else:
            before_node_colors.append('blue')
    
    # Draw before graph
    nx.draw_networkx_nodes(before_graph, before_scaled_pos, ax=axes[1, 0], 
                        node_size=600,
                        node_color=before_node_colors,
                        alpha=0.8)
    
    # Add node labels to before graph
    node_labels = {n: f"{n}: {before_labels[n]}" for n in before_graph.nodes()}
    nx.draw_networkx_labels(before_graph, before_scaled_pos, ax=axes[1, 0],
                        labels=node_labels,
                        font_size=10, font_color='black')
    
    # Draw edges with relationship labels for before graph
    nx.draw_networkx_edges(before_graph, before_scaled_pos, ax=axes[1, 0], 
                        width=1.5, 
                        alpha=0.6,
                        edge_color='gray')
    
    # Plot after scene graph with annotations
    axes[1, 1].set_title('After Scene Graph', fontsize=16)
    axes[1, 1].axis('off')
    
    # Get node positions for after graph
    after_pos = nx.get_node_attributes(after_graph, 'pos')
    after_labels = nx.get_node_attributes(after_graph, 'label')
    
    # Scale positions for better visualization (flip y-axis to match image coordinates)
    after_scaled_pos = {node: (after_pos[node][0], 1 - after_pos[node][1]) for node in after_pos}
    
    # Assign colors based on object status
    appeared_nodes = [node['id'] for node in change_analysis['appeared_objects']]
    moved_after_nodes = [match['after_id'] for match in change_analysis['moved_objects']]
    matched_after_nodes = [match['after_id'] for match in change_analysis['matched_objects']]
    
    # Define node colors for after graph
    after_node_colors = []
    for node in after_graph.nodes():
        if node in appeared_nodes:
            after_node_colors.append('purple')
        elif node in moved_after_nodes:
            after_node_colors.append('orange')
        elif node in matched_after_nodes:
            after_node_colors.append('green')
        else:
            after_node_colors.append('blue')
    
    # Draw after graph
    nx.draw_networkx_nodes(after_graph, after_scaled_pos, ax=axes[1, 1], 
                        node_size=600,
                        node_color=after_node_colors,
                        alpha=0.8)
    
    # Add node labels to after graph
    node_labels = {n: f"{n}: {after_labels[n]}" for n in after_graph.nodes()}
    nx.draw_networkx_labels(after_graph, after_scaled_pos, ax=axes[1, 1],
                        labels=node_labels,
                        font_size=10, font_color='black')
    
    # Draw edges with relationship labels for after graph
    nx.draw_networkx_edges(after_graph, after_scaled_pos, ax=axes[1, 1], 
                        width=1.5, 
                        alpha=0.6,
                        edge_color='gray')
    
    # Add legend explaining the colors
    legend_elements = [
        patches.Patch(facecolor='green', edgecolor='black', alpha=0.7, label='Matched Object'),
        patches.Patch(facecolor='red', edgecolor='black', alpha=0.7, label='Disappeared Object'),
        patches.Patch(facecolor='purple', edgecolor='black', alpha=0.7, label='Appeared Object'),
        patches.Patch(facecolor='orange', edgecolor='black', alpha=0.7, label='Moved Object')
    ]
    
    fig.legend(handles=legend_elements, loc='lower center', ncol=4, fontsize=12, bbox_to_anchor=(0.5, 0.02))
    
    # Add summary text
    summary_text = change_analysis['summary']
    fig.text(0.5, 0.97, "Scene Graph Comparison", fontsize=18, ha='center')
    fig.text(0.5, 0.94, summary_text, fontsize=12, ha='center', va='top')
    
    # Add timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    fig.text(0.95, 0.02, f"Generated: {timestamp}", fontsize=8, ha='right')
    
    # Adjust layout
    plt.tight_layout(rect=[0, 0.05, 1, 0.93])
    
    # Save if output directory is provided
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        plt.savefig(os.path.join(output_dir, 'scene_comparison.png'), dpi=300, bbox_inches='tight')
    
    return fig

def visualize_image_changes(before_image, after_image, before_graph, after_graph, 
                           change_analysis, output_dir=None):
    """
    Visualize the changes between two images by highlighting objects based on their status.
    
    Args:
        before_image (numpy.ndarray): Before image as RGB array
        after_image (numpy.ndarray): After image as RGB array
        before_graph (nx.Graph): Scene graph from the before image
        after_graph (nx.Graph): Scene graph from the after image
        change_analysis (dict): Results from compare_scene_graphs function
        output_dir (str): Directory to save visualization (optional)
    """
    # Create figure with 2 subplots
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 10))
    
    # Plot before image
    ax1.imshow(before_image)
    ax1.set_title('Before Image - Highlighted Changes', fontsize=16)
    ax1.axis('off')
    
    # Plot after image
    ax2.imshow(after_image)
    ax2.set_title('After Image - Highlighted Changes', fontsize=16)
    ax2.axis('off')
    
    # Get the original indices from change analysis
    disappeared_nodes = [node['id'] for node in change_analysis['disappeared_objects']]
    appeared_nodes = [node['id'] for node in change_analysis['appeared_objects']]
    moved_before_nodes = [match['before_id'] for match in change_analysis['moved_objects']]
    moved_after_nodes = [match['after_id'] for match in change_analysis['moved_objects']]
    matched_before_nodes = [match['before_id'] for match in change_analysis['matched_objects'] 
                           if match['before_id'] not in moved_before_nodes]
    matched_after_nodes = [match['after_id'] for match in change_analysis['matched_objects'] 
                          if match['after_id'] not in moved_after_nodes]
    
    # Define colors for different types of changes
    disappeared_color = to_rgba('red', 0.7)
    appeared_color = to_rgba('purple', 0.7)
    moved_color = to_rgba('orange', 0.7)
    matched_color = to_rgba('green', 0.4)
    
    # Get bounding boxes from graphs
    before_bboxes = nx.get_node_attributes(before_graph, 'bbox')
    after_bboxes = nx.get_node_attributes(after_graph, 'bbox')
    before_labels = nx.get_node_attributes(before_graph, 'label')
    after_labels = nx.get_node_attributes(after_graph, 'label')
    
    # Draw bounding boxes on before image
    for node_id, bbox in before_bboxes.items():
        if isinstance(bbox, str) and bbox.startswith('(') and bbox.endswith(')'):
            # Parse string representation of tuple
            bbox = eval(bbox)
        elif isinstance(bbox, list):
            bbox = tuple(bbox)
            
        x_min, y_min, x_max, y_max = bbox
        label = before_labels[node_id]
        
        # Determine color based on object status
        if node_id in disappeared_nodes:
            color = disappeared_color
            linestyle = '-'
            linewidth = 3
            show_label = True
            status = "Disappeared"
        elif node_id in moved_before_nodes:
            color = moved_color
            linestyle = '-'
            linewidth = 3
            show_label = True
            status = "Moved"
        elif node_id in matched_before_nodes:
            color = matched_color
            linestyle = '--'
            linewidth = 1.5
            show_label = False
            status = "Matched"
        else:
            continue  # Skip objects that don't match any category
        
        # Create rectangle patch
        rect = patches.Rectangle(
            (x_min, y_min), 
            x_max - x_min, 
            y_max - y_min, 
            linewidth=linewidth, 
            edgecolor=color[:3], 
            facecolor=color,
            linestyle=linestyle
        )
        ax1.add_patch(rect)
        
        # Add label if needed
        if show_label:
            ax1.text(
                x_min, 
                y_min - 5, 
                f"{node_id}: {label} ({status})", 
                color='white', 
                fontsize=10, 
                bbox=dict(facecolor=color[:3], alpha=0.9)
            )
    
    # Draw bounding boxes on after image
    for node_id, bbox in after_bboxes.items():
        if isinstance(bbox, str) and bbox.startswith('(') and bbox.endswith(')'):
            # Parse string representation of tuple
            bbox = eval(bbox)
        elif isinstance(bbox, list):
            bbox = tuple(bbox)
            
        x_min, y_min, x_max, y_max = bbox
        label = after_labels[node_id]
        
        # Determine color based on object status
        if node_id in appeared_nodes:
            color = appeared_color
            linestyle = '-'
            linewidth = 3
            show_label = True
            status = "Appeared"
        elif node_id in moved_after_nodes:
            color = moved_color
            linestyle = '-'
            linewidth = 3
            show_label = True
            status = "Moved"
        elif node_id in matched_after_nodes:
            color = matched_color
            linestyle = '--'
            linewidth = 1.5
            show_label = False
            status = "Matched"
        else:
            continue  # Skip objects that don't match any category
        
        # Create rectangle patch
        rect = patches.Rectangle(
            (x_min, y_min), 
            x_max - x_min, 
            y_max - y_min, 
            linewidth=linewidth, 
            edgecolor=color[:3], 
            facecolor=color,
            linestyle=linestyle
        )
        ax2.add_patch(rect)
        
        # Add label if needed
        if show_label:
            ax2.text(
                x_min, 
                y_min - 5, 
                f"{node_id}: {label} ({status})", 
                color='white', 
                fontsize=10, 
                bbox=dict(facecolor=color[:3], alpha=0.9)
            )
    
    # Add legend explaining the colors
    legend_elements = [
        patches.Patch(facecolor=matched_color, edgecolor='black', alpha=0.7, label='Unchanged Object'),
        patches.Patch(facecolor=disappeared_color, edgecolor='black', alpha=0.7, label='Disappeared Object'),
        patches.Patch(facecolor=appeared_color, edgecolor='black', alpha=0.7, label='Appeared Object'),
        patches.Patch(facecolor=moved_color, edgecolor='black', alpha=0.7, label='Moved Object')
    ]
    
    fig.legend(handles=legend_elements, loc='lower center', ncol=4, fontsize=12, bbox_to_anchor=(0.5, 0.02))
    
    # Add summary text
    summary_text = change_analysis['summary']
    fig.text(0.5, 0.97, "Image Change Comparison", fontsize=18, ha='center')
    fig.text(0.5, 0.94, summary_text, fontsize=12, ha='center', va='top')
    
    # Add timestamp
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    fig.text(0.95, 0.02, f"Generated: {timestamp}", fontsize=8, ha='right')
    
    # Adjust layout
    plt.tight_layout(rect=[0, 0.05, 1, 0.93])
    
    # Save if output directory is provided
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        plt.savefig(os.path.join(output_dir, 'image_changes.png'), dpi=300, bbox_inches='tight')
    
    return fig

def generate_change_report(before_graph, after_graph, change_analysis, output_dir=None):
    """
    Generate a detailed report of the changes between two scenes.
    
    Args:
        before_graph (nx.Graph): Scene graph from the before image
        after_graph (nx.Graph): Scene graph from the after image
        change_analysis (dict): Results from compare_scene_graphs function
        output_dir (str): Directory to save the report (optional)
        
    Returns:
        str: Change report content
    """
    # Get node labels
    before_labels = nx.get_node_attributes(before_graph, 'label')
    after_labels = nx.get_node_attributes(after_graph, 'label')
    
    # Create report content
    report = []
    
    # Add header
    report.append("# Scene Change Analysis Report")
    report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("")
    
    # Add summary
    report.append("## Summary")
    report.append(change_analysis['summary'])
    report.append("")
    
    # Add metrics
    report.append("## Scene Metrics")
    metrics = change_analysis['metrics']
    report.append("### Before Scene")
    report.append(f"- Objects: {metrics['before_object_count']}")
    report.append(f"- Relationships: {metrics['before_relationship_count']}")
    report.append(f"- Graph Density: {metrics['before_density']:.3f}")
    report.append("")
    
    report.append("### After Scene")
    report.append(f"- Objects: {metrics['after_object_count']}")
    report.append(f"- Relationships: {metrics['after_relationship_count']}")
    report.append(f"- Graph Density: {metrics['after_density']:.3f}")
    report.append("")
    
    # Add object appearance/disappearance details
    report.append("## Object Changes")
    
    # Disappeared objects
    if metrics['disappeared_count'] > 0:
        report.append("### Disappeared Objects")
        for obj in change_analysis['disappeared_objects']:
            report.append(f"- Object {obj['id']}: {obj['label']} (position: {obj['position']})")
        report.append("")
    
    # Appeared objects
    if metrics['appeared_count'] > 0:
        report.append("### Appeared Objects")
        for obj in change_analysis['appeared_objects']:
            report.append(f"- Object {obj['id']}: {obj['label']} (position: {obj['position']})")
        report.append("")
    
    # Moved objects
    if metrics['moved_count'] > 0:
        report.append("### Moved Objects")
        for obj in change_analysis['moved_objects']:
            report.append(f"- {obj['label']} moved (distance: {obj['position_change']:.3f})")
        report.append("")
    
    # Relationship changes
    if len(change_analysis['relationship_changes']) > 0:
        report.append("### Relationship Changes")
        for rel in change_analysis['relationship_changes']:
            obj1, obj2 = rel['labels']
            before_rel = rel['before_relationship']
            after_rel = rel['after_relationship']
            
            if before_rel == 'none':
                report.append(f"- New relationship: {obj1} is now {after_rel} {obj2}")
            elif after_rel == 'none':
                report.append(f"- Lost relationship: {obj1} is no longer {before_rel} {obj2}")
            else:
                report.append(f"- Changed relationship: {obj1} was {before_rel} {obj2}, now is {after_rel} {obj2}")
        report.append("")
    
    # Save report to file if output directory is provided
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        report_path = os.path.join(output_dir, 'change_report.md')
        with open(report_path, 'w') as f:
            f.write('\n'.join(report))
        print(f"Report saved to {report_path}")
    
    return '\n'.join(report)

def compare_scene_graphs_from_json(before_graph_json, after_graph_json, 
                                  before_image_path, after_image_path, 
                                  output_dir=None):
    """
    Compare two scene graphs from JSON data and generate visualizations and reports.
    
    Args:
        before_graph_json (str or dict): JSON file path or dict for before graph
        after_graph_json (str or dict): JSON file path or dict for after graph
        before_image_path (str): Path to before image
        after_image_path (str): Path to after image
        output_dir (str): Directory to save outputs (optional)
        
    Returns:
        dict: Comparison results
    """
    # Create output directory if provided
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
    
    # Step 1: Load scene graphs
    print("Loading scene graphs...")
    before_graph = load_scene_graph_from_json(before_graph_json)
    after_graph = load_scene_graph_from_json(after_graph_json)
    
    # Step 2: Load images
    print("Loading images...")
    before_image = load_image(before_image_path)
    after_image = load_image(after_image_path)
    
    # Step 3: Compare scene graphs
    print("Comparing scene graphs...")
    change_analysis = compare_scene_graphs(
        before_graph,
        after_graph,
        similarity_threshold=0.7
    )
    
    # Step 4: Generate visualizations
    print("Generating visualizations...")
    scene_comparison_fig = visualize_scene_comparison(
        before_image,
        after_image,
        before_graph,
        after_graph,
        change_analysis,
        output_dir
    )
    
    image_changes_fig = visualize_image_changes(
        before_image,
        after_image,
        before_graph,
        after_graph,
        change_analysis,
        output_dir
    )
    
    # Step 5: Generate report
    print("Generating change report...")
    report = generate_change_report(
        before_graph,
        after_graph,
        change_analysis,
        output_dir
    )
    
    # Step 6: Save change analysis to JSON
    if output_dir:
        with open(os.path.join(output_dir, 'change_analysis.json'), 'w') as f:
            # Convert complex objects to serializable format
            def json_converter(obj):
                if isinstance(obj, tuple):
                    return list(obj)
                return str(obj)
            
            json.dump(change_analysis, f, default=json_converter, indent=2)
    
    print(f"All comparison results saved to {output_dir}")
    
    return {
        'change_analysis': change_analysis,
        'report': report,
        'figures': {
            'scene_comparison': scene_comparison_fig,
            'image_changes': image_changes_fig
        }
    }

if __name__ == "__main__":
    # Example usage
    before_graph_json = "outputs/scene_graph_before.json"
    after_graph_json = "outputs/scene_graph_after.json"
    before_image_path = "data/before_shelf.jpg"
    after_image_path = "data/after_image.jpeg"
    
    
    
    # Create output directory with timestamp
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = f"output/scene_comparison_{timestamp}"
    
    # Compare scene graphs and generate visualizations and report
    results = compare_scene_graphs_from_json(
        before_graph_json,
        after_graph_json,
        before_image_path,
        after_image_path,
        output_dir
    )
    
    print("\n" + results['change_analysis']['summary'])