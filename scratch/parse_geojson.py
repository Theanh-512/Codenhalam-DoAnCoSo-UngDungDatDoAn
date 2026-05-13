import json

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
            
        # Extract address
        street = props.get('addr:street', '').replace('"', '\\"')
        house_num = props.get('addr:housenumber', '').replace('"', '\\"')
        address = f"{house_num} {street}".strip()
        if not address:
            address = "Hồ Chí Minh"
        else:
            address += ", Hồ Chí Minh"
            
        coords = geom.get('coordinates', [0, 0])
        lng, lat = coords
        
        # Determine description based on cuisine or name
        cuisine = props.get('cuisine', 'Địa điểm ăn uống').replace('"', '\\"')
        description = f"Phục vụ các món {cuisine}"
        
        restaurants.append({
            'name': name,
            'description': description,
            'address': address,
            'lat': lat,
            'lng': lng
        })
        
        if len(restaurants) >= 30: # Limit to 30 for seeding
            break
            
    return restaurants

def generate_cs_code(restaurants):
    code = ""
    for r in restaurants:
        code += f"""
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
    return code

if __name__ == "__main__":
    res_list = parse_geojson('export.geojson')
    print(generate_cs_code(res_list))
