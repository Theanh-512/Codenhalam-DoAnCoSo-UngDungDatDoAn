import json
import re
import os

def parse_geojson(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    features = data.get('features', [])
    restaurants = []
    
    for feat in features:
        props = feat.get('properties', {})
        geom = feat.get('geometry', {})
        
        name = props.get('name', '').replace('"', '\\"')
        if not name:
            continue
            
        street = props.get('addr:street', '').replace('"', '\\"')
        house_num = props.get('addr:housenumber', '').replace('"', '\\"')
        address = f"{house_num} {street}".strip()
        if not address:
            address = "Hồ Chí Minh"
        else:
            address += ", Hồ Chí Minh"
            
        coords = geom.get('coordinates', [0, 0])
        lng, lat = coords
        
        cuisine = props.get('cuisine', 'Địa điểm ăn uống').replace('"', '\\"')
        description = f"Phục vụ các món {cuisine}"
        
        restaurants.append({
            'name': name,
            'description': description,
            'address': address,
            'lat': lat,
            'lng': lng
        })
        
        if len(restaurants) >= 30:
            break
            
    return restaurants

def update_seed_data(seed_file_path, geojson_file_path):
    restaurants = parse_geojson(geojson_file_path)
    
    res_code = ""
    for r in restaurants:
        res_code += f"""
                    new Restaurant 
                    {{ 
                        Name = "{r['name']}", 
                        Description = "{r['description']}", 
                        Address = "{r['address']}",
                        ImageUrl = "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=500",
                        Latitude = {r['lat']}, Longitude = {r['lng']},
                        OpeningHours = "08:00-22:00",
                        IsActive = true,
                        CreatedDate = System.DateTime.UtcNow
                    }},"""

    with open(seed_file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find the restaurants list
    pattern = r'var restaurants = new List<Restaurant>\s*\{.*?\};'
    replacement = f'var restaurants = new List<Restaurant>\n                {{{res_code}\n                }};'
    
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open(seed_file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully updated SeedData.cs")

if __name__ == "__main__":
    update_seed_data(
        'Backend/Infrastructure/Data/SeedData.cs',
        'export.geojson'
    )
