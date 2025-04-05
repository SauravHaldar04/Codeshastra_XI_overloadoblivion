import os
import json
import requests
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont
import textwrap

class SceneChangeSummarizer:
    """
    A class to generate natural language summaries of scene changes using Cohere LLM.
    """
    
    def __init__(self, api_key=None, model=None):
        """
        Initialize the scene change summarizer.
        
        Args:
            api_key (str, optional): API key for Cohere
            model (str, optional): Model name to use for summarization
        """
        self.api_key = api_key or os.environ.get("COHERE_API_KEY")
        self.api_url = "https://api.cohere.ai/v1/generate"
        self.model = model or "command"
        
        if not self.api_key:
            print("Warning: No Cohere API key provided. Please set the COHERE_API_KEY environment variable or provide an API key.")
    
    def _call_cohere_api(self, prompt):
        """
        Call the Cohere API to generate a response.
        
        Args:
            prompt (str): The prompt for the LLM
            
        Returns:
            str: The LLM response
        """
        if not self.api_key:
            return "Error: No Cohere API key provided. Unable to generate summary."
        
        try:
            # Make API request
            headers = {
                "Authorization": f"BEARER {self.api_key}",
                "Content-Type": "application/json"
            }
            
            data = {
                "model": self.model,
                "prompt": prompt,
                "max_tokens": 800,
                "temperature": 0.7,
                "k": 0,
                "stop_sequences": [],
                "return_likelihoods": "NONE"
            }
            
            response = requests.post(self.api_url, headers=headers, json=data)
            response.raise_for_status()
            
            # Extract and return the response text
            result = response.json()
            return result["generations"][0]["text"].strip()
            
        except Exception as e:
            print(f"Error calling Cohere API: {str(e)}")
            # Provide a fallback summary
            return self._generate_fallback_summary(prompt)
    
    def _generate_fallback_summary(self, prompt):
        """
        Generate a fallback summary when the LLM API call fails.
        
        Args:
            prompt (str): The original prompt
            
        Returns:
            str: A simple summary based on the prompt data
        """
        # Extract basic data from prompt
        summary_lines = []
        summary_lines.append("Scene Change Summary (Generated without LLM):")
        
        # Look for metrics in the prompt
        if "Before scene had" in prompt:
            metrics_lines = []
            for line in prompt.split("\n"):
                if "Before scene had" in line or "After scene has" in line:
                    metrics_lines.append(line)
            summary_lines.extend(metrics_lines)
        
        # Count objects by category
        appeared_count = 0
        disappeared_count = 0
        moved_count = 0
        
        for line in prompt.split("\n"):
            if "APPEARED OBJECTS" in line:
                appeared_count = int(line.split("(")[1].split(")")[0]) if "(" in line else 0
                
            elif "DISAPPEARED OBJECTS" in line:
                disappeared_count = int(line.split("(")[1].split(")")[0]) if "(" in line else 0
                
            elif "MOVED OBJECTS" in line:
                moved_count = int(line.split("(")[1].split(")")[0]) if "(" in line else 0
        
        summary_lines.append(f"\nScene Changes:")
        summary_lines.append(f"- {appeared_count} new objects appeared")
        summary_lines.append(f"- {disappeared_count} objects disappeared")
        summary_lines.append(f"- {moved_count} objects moved")
        
        return "\n".join(summary_lines)
    
    def generate_summary(self, change_analysis, verbose=False):
        """
        Generate a natural language summary of scene changes.
        
        Args:
            change_analysis (dict): Change analysis data from scene_graph_comparator
            verbose (bool): Whether to include detailed information in the prompt
            
        Returns:
            str: Natural language summary of changes
        """
        # Extract key information for the prompt
        metrics = change_analysis.get('metrics', {})
        appeared = change_analysis.get('appeared_objects', [])
        disappeared = change_analysis.get('disappeared_objects', [])
        moved = change_analysis.get('moved_objects', [])
        relationships = change_analysis.get('relationship_changes', [])
        
        # Create a prompt for the LLM
        prompt = """You are an AI assistant that specializes in analyzing visual scene changes and describing them in natural language.
Your task is to interpret data about how objects have changed between two images, and provide a clear, concise summary of these changes.
Focus on making the description intuitive and easy to understand.

Here's the analysis data of changes between two scenes:

"""
        
        # Add metrics
        before_obj_count = metrics.get('before_object_count', 0)
        before_rel_count = metrics.get('before_relationship_count', 0)
        after_obj_count = metrics.get('after_object_count', 0)
        after_rel_count = metrics.get('after_relationship_count', 0)
        
        prompt += f"Before scene had {before_obj_count} objects and {before_rel_count} relationships.\n"
        prompt += f"After scene has {after_obj_count} objects and {after_rel_count} relationships.\n\n"
        
        # Add appeared objects
        if appeared:
            prompt += f"APPEARED OBJECTS ({len(appeared)}):\n"
            for obj in appeared[:10]:  # Limit to first 10 if there are many
                prompt += f"- {obj['label']} appeared\n"
            if len(appeared) > 10:
                prompt += f"- ... and {len(appeared) - 10} more objects appeared\n"
            prompt += "\n"
        
        # Add disappeared objects
        if disappeared:
            prompt += f"DISAPPEARED OBJECTS ({len(disappeared)}):\n"
            for obj in disappeared[:10]:  # Limit to first 10 if there are many
                prompt += f"- {obj['label']} disappeared\n"
            if len(disappeared) > 10:
                prompt += f"- ... and {len(disappeared) - 10} more objects disappeared\n"
            prompt += "\n"
        
        # Add moved objects
        if moved:
            prompt += f"MOVED OBJECTS ({len(moved)}):\n"
            for obj in moved[:10]:  # Limit to first 10 if there are many
                prompt += f"- {obj['label']} moved (distance: {obj.get('position_change', 0):.3f})\n"
            if len(moved) > 10:
                prompt += f"- ... and {len(moved) - 10} more objects moved\n"
            prompt += "\n"
        
        # Add relationship changes
        if relationships:
            prompt += f"RELATIONSHIP CHANGES ({len(relationships)}):\n"
            for rel in relationships[:10]:  # Limit to first 10 if there are many
                obj1, obj2 = rel.get('labels', ('unknown', 'unknown'))
                before_rel = rel.get('before_relationship', 'none')
                after_rel = rel.get('after_relationship', 'none')
                
                if before_rel == 'none':
                    prompt += f"- New relationship: {obj1} is now {after_rel} {obj2}\n"
                elif after_rel == 'none':
                    prompt += f"- Lost relationship: {obj1} is no longer {before_rel} {obj2}\n"
                else:
                    prompt += f"- Changed relationship: {obj1} was {before_rel} {obj2}, now is {after_rel} {obj2}\n"
            
            if len(relationships) > 10:
                prompt += f"- ... and {len(relationships) - 10} more relationship changes\n"
            prompt += "\n"
        
        # Add instruction
        prompt += """
Based on this data, please write a clear, concise description of the changes between the two scenes.
- Use natural language that a human would understand easily.
- Focus on the most significant changes first.
- Group similar changes together.
- If there are patterns or trends in the changes, point them out.
- Make logical inferences about what might have happened (e.g., "Items were reorganized on the shelf").
- Keep your response to about 3-5 paragraphs.

Scene Change Summary:
"""
        
        # Call Cohere API
        return self._call_cohere_api(prompt)
    
    def create_visual_summary(self, change_analysis, before_image_path, after_image_path, output_dir=None):
        """
        Create a visual summary of scene changes with natural language description.
        
        Args:
            change_analysis (dict): Change analysis data from scene_graph_comparator
            before_image_path (str): Path to before image
            after_image_path (str): Path to after image
            output_dir (str): Directory to save the visual summary (optional)
            
        Returns:
            PIL.Image: Visual summary as a PIL Image
        """
        # Generate a natural language summary
        summary_text = self.generate_summary(change_analysis)
        
        try:
            # Load images
            before_image = Image.open(before_image_path)
            after_image = Image.open(after_image_path)
            
            # Resize images to the same height
            target_height = 400
            before_ratio = before_image.width / before_image.height
            after_ratio = after_image.width / after_image.height
            
            before_image = before_image.resize((int(target_height * before_ratio), target_height))
            after_image = after_image.resize((int(target_height * after_ratio), target_height))
            
            # Calculate dimensions for the combined image
            total_width = before_image.width + after_image.width + 40  # Add 40px gap
            total_height = target_height + 300  # Add 300px for the text
            
            # Create a new image with white background
            combined_image = Image.new('RGB', (total_width, total_height), (255, 255, 255))
            
            # Paste the before and after images
            combined_image.paste(before_image, (0, 0))
            combined_image.paste(after_image, (before_image.width + 40, 0))
            
            # Add text using ImageDraw
            draw = ImageDraw.Draw(combined_image)
            
            # Try to load a font, fall back to default if not available
            try:
                font_title = ImageFont.truetype("arial.ttf", 22)
                font_text = ImageFont.truetype("arial.ttf", 16)
            except IOError:
                try:
                    # Try DejaVuSans which is often available on Linux
                    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 22)
                    font_text = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 16)
                except:
                    font_title = ImageFont.load_default()
                    font_text = ImageFont.load_default()
            
            # Add titles
            draw.text((10, 10), "Before", fill=(255, 0, 0), font=font_title)
            draw.text((before_image.width + 50, 10), "After", fill=(0, 128, 0), font=font_title)
            
            # Add summary title
            draw.text((10, target_height + 20), "Scene Change Summary:", fill=(0, 0, 0), font=font_title)
            
            # Add summary text with word wrap
            text_start_y = target_height + 60
            text_width = total_width - 20
            y_offset = text_start_y
            
            # Simple text wrapping function for PIL
            wrapped_text = textwrap.fill(summary_text, width=90)  # Adjust width as needed
            lines = wrapped_text.split('\n')
            
            for line in lines:
                if y_offset > total_height - 30:
                    # We're running out of space
                    draw.text((10, y_offset), "... (summary truncated due to space constraints)", 
                             fill=(0, 0, 0), font=font_text)
                    break
                    
                draw.text((10, y_offset), line, fill=(0, 0, 0), font=font_text)
                y_offset += 24  # Line height
            
            # Add timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            draw.text((total_width - 200, total_height - 20), f"Generated: {timestamp}", 
                     fill=(128, 128, 128), font=font_text)
            
            # Save if output directory is provided
            if output_dir:
                os.makedirs(output_dir, exist_ok=True)
                output_path = os.path.join(output_dir, 'visual_summary.png')
                combined_image.save(output_path)
                print(f"Visual summary saved to {output_path}")
            
            return combined_image
            
        except Exception as e:
            print(f"Error creating visual summary: {str(e)}")
            # Just return None instead of creating a fallback image
            return None
    
    def generate_structured_output(self, change_analysis, before_image_path=None, after_image_path=None, output_dir=None):
        """
        Generate a structured output with natural language summary and visual summary.
        
        Args:
            change_analysis (dict): Change analysis data from scene_graph_comparator
            before_image_path (str, optional): Path to before image
            after_image_path (str, optional): Path to after image
            output_dir (str, optional): Directory to save outputs
            
        Returns:
            dict: Dictionary containing the structured output
        """
        # Generate text summary
        print("Generating natural language summary...")
        text_summary = self.generate_summary(change_analysis)
        
        # Get metrics from change_analysis, ensure it's properly initialized
        metrics = change_analysis.get('metrics', {})
        
        # Create output structure
        output = {
            'text_summary': text_summary,
            'metrics': metrics,
            'timestamp': datetime.now().isoformat(),
            'visual_summary_path': None
        }
        
        # Create visual summary if images are provided
        if before_image_path and after_image_path and os.path.exists(before_image_path) and os.path.exists(after_image_path):
            print("Creating visual summary...")
            try:
                visual_summary = self.create_visual_summary(
                    change_analysis,
                    before_image_path,
                    after_image_path,
                    output_dir
                )
                
                if output_dir and visual_summary:
                    output['visual_summary_path'] = os.path.join(output_dir, 'visual_summary.png')
            except Exception as e:
                print(f"Error creating visual summary: {str(e)}")
                # Continue with other outputs
        else:
            print("Skipping visual summary: Image paths not provided or files not found.")
        
        # Save structured output to files if output directory is provided
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            
            # Save text summary
            with open(os.path.join(output_dir, 'text_summary.txt'), 'w') as f:
                f.write(text_summary)
                
            # Save structured output as JSON
            with open(os.path.join(output_dir, 'structured_output.json'), 'w') as f:
                appeared_objs = change_analysis.get('appeared_objects', [])
                disappeared_objs = change_analysis.get('disappeared_objects', [])
                moved_objs = change_analysis.get('moved_objects', [])
                
                # Create a simplified version without large data structures
                simplified_output = {
                    'text_summary': text_summary,
                    'metrics': metrics,
                    'changes': {
                        'appeared_count': len(appeared_objs),
                        'disappeared_count': len(disappeared_objs),
                        'moved_count': len(moved_objs),
                        'relationship_changes_count': len(change_analysis.get('relationship_changes', []))
                    },
                    'timestamp': datetime.now().isoformat(),
                    'visual_summary_path': output.get('visual_summary_path')
                }
                
                # Use a custom encoder to handle non-serializable objects
                class CustomEncoder(json.JSONEncoder):
                    def default(self, obj):
                        try:
                            return json.JSONEncoder.default(self, obj)
                        except TypeError:
                            return str(obj)
                
                json.dump(simplified_output, f, indent=2, cls=CustomEncoder)
        
        return output

def process_scene_changes(change_analysis, before_image_path=None, after_image_path=None, output_dir=None, api_key=None):
    """
    Process scene changes and generate structured output with Cohere LLM summary.
    
    Args:
        change_analysis (dict): Change analysis data from scene_graph_comparator
        before_image_path (str, optional): Path to before image
        after_image_path (str, optional): Path to after image
        output_dir (str, optional): Directory to save outputs
        api_key (str, optional): API key for Cohere
        
    Returns:
        dict: Dictionary containing the structured output
    """
    # Create summarizer
    summarizer = SceneChangeSummarizer(api_key=api_key)
    
    # Generate structured output
    output = summarizer.generate_structured_output(
        change_analysis,
        before_image_path,
        after_image_path,
        output_dir
    )
    
    print("Scene change summary generated successfully.")
    if output_dir:
        print(f"Results saved to {output_dir}")
        
    return output

# Example usage
if __name__ == "__main__":
    # Example usage showing how to call the code directly
    # Get Cohere API key from environment variable
    api_key = os.environ.get("COHERE_API_KEY")
    
    # Create timestamp for output directory
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_dir = f"output/summary_{timestamp}"
    
    # Load change analysis from a file
    change_analysis_path = "output/scene_comparison_20250405-194328/change_analysis.json"
    
    try:
        with open(change_analysis_path, 'r') as f:
            change_analysis = json.load(f)
            
        # Process scene changes
        output = process_scene_changes(
            change_analysis,
            "data/before_shelf.jpg",
            "data/after_image.jpeg", 
            output_dir,
            api_key
        )
        
        print("\nSummary:")
        print(output['text_summary'])
    except Exception as e:
        print(f"Error: {str(e)}")