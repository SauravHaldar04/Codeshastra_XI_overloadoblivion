import os
import json
import time
from datetime import datetime
import torch

# Import our custom modules
from scene_graph_creator import process_image_to_scene_graph
from scene_graph_comparer import compare_scene_graphs_from_json
from change_summarizer import process_scene_changes

def run_streamlined_pipeline():
    """
    Run a streamlined scene analysis pipeline that doesn't save intermediate results.
    
    This function:
    1. Uses default paths for before/after images
    2. Creates scene graphs for both images
    3. Compares the scene graphs
    4. Generates a natural language summary using Cohere
    5. Returns the results without saving intermediate files
    
    Returns:
        dict: Results from the pipeline
    """
    print("Starting streamlined scene analysis pipeline...")
    
    # Default paths - modify these to point to your actual images
    before_image_path = "data/before_image.jpg"
    after_image_path = "data/after_image.jpg"
    
    # Check if the default images exist
    if not os.path.exists(before_image_path):
        print(f"Warning: Default before image not found at {before_image_path}")
        before_image_path = input("Enter path to before image: ")
    
    if not os.path.exists(after_image_path):
        print(f"Warning: Default after image not found at {after_image_path}")
        after_image_path = input("Enter path to after image: ")
    
    # Default class list - common objects that might be found in scenes
    class_list = [
        "person", "chair", "table", "desk", "computer", "laptop", "keyboard", "mouse",
        "monitor", "screen", "phone", "mobile", "bottle", "cup", "glass", "book",
        "paper", "document", "box", "container", "bag", "backpack", "lamp", "light",
        "pen", "pencil", "notebook", "folder", "shelf", "cabinet", "drawer", "plant",
        "vase", "picture", "frame", "clock", "watch", "wallet", "keys", "cord",
        "cable", "charger", "adapter", "headphones", "speaker", "remote", "tv",
        "television", "snack", "food", "drink", "plate", "bowl", "fork", "knife", 
        "spoon", "scissors", "tape", "stapler", "calculator", "glasses", "sunglasses"
    ]
    
    try:
        # Step 1: Create scene graph for before image
        print(f"\nStep 1/4: Processing before image ({before_image_path})...")
        before_start_time = time.time()
        
        before_graph = process_image_to_scene_graph(
            before_image_path,
            class_list,
            output_dir=None,  # No output directory
            save_visualization=False,  # Don't save visualization
            return_json=True
        )
        
        before_time = time.time() - before_start_time
        print(f"Before image processing completed in {before_time:.2f} seconds")
        
        # Step 2: Create scene graph for after image
        print(f"\nStep 2/4: Processing after image ({after_image_path})...")
        after_start_time = time.time()
        
        after_graph = process_image_to_scene_graph(
            after_image_path,
            class_list,
            output_dir=None,  # No output directory
            save_visualization=False,  # Don't save visualization
            return_json=True
        )
        
        after_time = time.time() - after_start_time
        print(f"After image processing completed in {after_time:.2f} seconds")
        
        # Step 3: Compare the scene graphs
        print("\nStep 3/4: Comparing scene graphs...")
        comparison_start_time = time.time()
        
        comparison_results = compare_scene_graphs_from_json(
            before_graph,
            after_graph,
            before_image_path,
            after_image_path,
            output_dir=None  # No output directory
        )
        
        comparison_time = time.time() - comparison_start_time
        print(f"Scene graph comparison completed in {comparison_time:.2f} seconds")
        
        # Step 4: Generate summary using Cohere
        print("\nStep 4/4: Generating summary with Cohere...")
        summary_start_time = time.time()
        
        # Try to get Cohere API key from environment
        cohere_api_key = os.environ.get("COHERE_API_KEY")
        if not cohere_api_key:
            print("COHERE_API_KEY environment variable not set.")
            print("Natural language summary will be generated without LLM.")
        
        summary_results = process_scene_changes(
            comparison_results['change_analysis'],
            before_image_path,
            after_image_path,
            output_dir=None,  # No output directory
            api_key=cohere_api_key
        )
        
        summary_time = time.time() - summary_start_time
        print(f"Summary generation completed in {summary_time:.2f} seconds")
        
        # Create the final results
        final_results = {
            "status": "success",
            "timestamp": datetime.now().isoformat(),
            "processing_times": {
                "before_image": before_time,
                "after_image": after_time,
                "comparison": comparison_time,
                "summary": summary_time,
                "total": before_time + after_time + comparison_time + summary_time
            },
            "input": {
                "before_image": before_image_path,
                "after_image": after_image_path,
                "class_count": len(class_list)
            },
            "scene_analysis": {
                "before_objects": before_graph.get('metadata', {}).get('node_count', 0),
                "after_objects": after_graph.get('metadata', {}).get('node_count', 0),
                "changes": {
                    "appeared": len(comparison_results['change_analysis'].get('appeared_objects', [])),
                    "disappeared": len(comparison_results['change_analysis'].get('disappeared_objects', [])),
                    "moved": len(comparison_results['change_analysis'].get('moved_objects', [])),
                    "relationship_changes": len(comparison_results['change_analysis'].get('relationship_changes', []))
                }
            },
            "summary": summary_results.get('text_summary', 'No summary generated')
        }
        
        # Display the text summary
        print("\n" + "="*50)
        print("SCENE CHANGE SUMMARY:")
        print("="*50)
        print(final_results["summary"])
        print("="*50)
        
        return final_results
        
    except Exception as e:
        error_message = f"Error in pipeline: {str(e)}"
        print(f"\nERROR: {error_message}")
        
        return {
            "status": "error",
            "error": error_message,
            "timestamp": datetime.now().isoformat()
        }

def cleanup_cuda_memory():
    """
    Clean up CUDA memory to help avoid out-of-memory errors between runs.
    """
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        print("CUDA memory cache cleared")

if __name__ == "__main__":
    # Current system information
    print(f"Current Date and Time (UTC): {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Current User's Login: {os.environ.get('USER', 'unknown')}")
    print("\n")
    
    try:
        # Clear memory before starting
        cleanup_cuda_memory()
        
        # Run the pipeline
        result = run_streamlined_pipeline()
        
        if result["status"] == "success":
            print("\nPipeline completed successfully!")
        else:
            print(f"\nPipeline failed with error: {result.get('error', 'Unknown error')}")
        
        # Clear memory after finishing
        cleanup_cuda_memory()
        
    except KeyboardInterrupt:
        print("\nPipeline interrupted by user.")
    except Exception as e:
        print(f"\nUnexpected error in main: {str(e)}")
        import traceback
        traceback.print_exc()