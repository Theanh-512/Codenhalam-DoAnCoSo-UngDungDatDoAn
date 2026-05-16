import requests

BASE_URL = "http://localhost:5149"

def test_api():
    try:
        # 1. Get first restaurant
        print("Fetching restaurants...")
        res = requests.get(f"{BASE_URL}/api/Restaurants")
        if res.status_code != 200:
            print(f"Failed to fetch restaurants: {res.status_code}")
            return
        
        restaurants = res.json()
        if not restaurants:
            print("No restaurants found.")
            return
        
        first_res = restaurants[0]
        res_id = first_res.get('id') or first_res.get('Id')
        print(f"Found restaurant: {first_res.get('name')} with ID: {res_id}")
        
        # 2. Get menu
        print(f"Fetching menu for ID: {res_id}...")
        menu_res = requests.get(f"{BASE_URL}/api/Restaurants/{res_id}/menu")
        print(f"Status Code: {menu_res.status_code}")
        if menu_res.status_code == 200:
            menu = menu_res.json()
            print(f"Found {len(menu)} items in menu.")
            if menu:
                print(f"First item: {menu[0].get('name')}")
        else:
            print(f"Response: {menu_res.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_api()
