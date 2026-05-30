import psycopg2
import random
from datetime import datetime, timedelta
import uuid

# Connection string from appsettings.json
conn_string = "host='aws-1-ap-southeast-2.pooler.supabase.com' port='5432' dbname='postgres' user='postgres.wbusmwbzqlkyhxtoghsl' password='Codenhalam123456'"

def generate_behavior_data(user_email="user1@example.com"):
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()

        # 1. Get User ID
        cursor.execute("SELECT \"Id\" FROM \"Users\" WHERE \"Email\" = %s", (user_email,))
        user_row = cursor.fetchone()
        
        if not user_row:
            print(f"User {user_email} not found. Please create the user first in the app.")
            return
            
        user_id = user_row[0]
        print(f"Found User ID: {user_id}")

        # 2. Get some restaurants
        cursor.execute("SELECT \"Id\", \"Latitude\", \"Longitude\" FROM \"Restaurants\"")
        restaurants = cursor.fetchall()
        
        if not restaurants:
            print("No restaurants found in the database.")
            return

        # 3. Get food items
        cursor.execute("SELECT \"Id\", \"Price\", \"RestaurantId\" FROM \"FoodItems\"")
        food_items = cursor.fetchall()
        
        food_by_restaurant = {}
        for f_id, price, r_id in food_items:
            if r_id not in food_by_restaurant:
                food_by_restaurant[r_id] = []
            food_by_restaurant[r_id].append((f_id, price))

        if not food_by_restaurant:
            print("No food items found in the database.")
            return

        # Generate data for the past 30 days
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=30)
        
        # Action types for TrackingLog
        action_types = ["VIEW_RESTAURANT", "VIEW_MENU_ITEM", "ADD_TO_CART", "CHECKOUT"]
        
        orders_created = 0
        logs_created = 0

        # Simulate ~15 orders over 30 days
        for i in range(15):
            # Random date within the last 30 days
            random_days = random.randint(0, 30)
            random_hours = random.randint(10, 21) # Lunch/Dinner times roughly
            random_minutes = random.randint(0, 59)
            order_date = start_date + timedelta(days=random_days, hours=random_hours, minutes=random_minutes)
            
            # Select a random restaurant that has food items
            valid_restaurants = [r for r in restaurants if r[0] in food_by_restaurant]
            if not valid_restaurants:
                break
                
            restaurant = random.choice(valid_restaurants)
            rest_id, rest_lat, rest_lon = restaurant
            
            # Session ID for this interaction flow
            session_id = str(uuid.uuid4())
            
            # Simulate User Location (slightly offset from restaurant)
            user_lat = float(rest_lat) + random.uniform(-0.02, 0.02) if rest_lat else 10.8231
            user_lon = float(rest_lon) + random.uniform(-0.02, 0.02) if rest_lon else 106.6297

            # Generate Tracking Logs leading up to the order
            # View Restaurant
            cursor.execute("""
                INSERT INTO \"TrackingLogs\" 
                (\"UserId\", \"RestaurantId\", \"SessionId\", \"ActionType\", \"Latitude\", \"Longitude\", \"Timestamp\", \"CreatedDate\", \"DeviceInfo\")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (user_id, rest_id, session_id, "VIEW_RESTAURANT", user_lat, user_lon, order_date - timedelta(minutes=5), order_date - timedelta(minutes=5), "iPhone 13"))
            logs_created += 1

            # View Items
            available_foods = food_by_restaurant[rest_id]
            items_to_order = random.sample(available_foods, k=min(random.randint(1, 3), len(available_foods)))
            
            for food_id, _ in items_to_order:
                cursor.execute("""
                    INSERT INTO \"TrackingLogs\" 
                    (\"UserId\", \"RestaurantId\", \"SessionId\", \"ActionType\", \"Latitude\", \"Longitude\", \"Timestamp\", \"CreatedDate\", \"DeviceInfo\")
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (user_id, rest_id, session_id, "VIEW_MENU_ITEM", user_lat, user_lon, order_date - timedelta(minutes=3), order_date - timedelta(minutes=3), "iPhone 13"))
                logs_created += 1

                cursor.execute("""
                    INSERT INTO \"TrackingLogs\" 
                    (\"UserId\", \"RestaurantId\", \"SessionId\", \"ActionType\", \"Latitude\", \"Longitude\", \"Timestamp\", \"CreatedDate\", \"DeviceInfo\")
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (user_id, rest_id, session_id, "ADD_TO_CART", user_lat, user_lon, order_date - timedelta(minutes=1), order_date - timedelta(minutes=1), "iPhone 13"))
                logs_created += 1

            # Checkout log
            cursor.execute("""
                INSERT INTO \"TrackingLogs\" 
                (\"UserId\", \"RestaurantId\", \"SessionId\", \"ActionType\", \"Latitude\", \"Longitude\", \"Timestamp\", \"CreatedDate\", \"DeviceInfo\")
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (user_id, rest_id, session_id, "CHECKOUT", user_lat, user_lon, order_date, order_date, "iPhone 13"))
            logs_created += 1

            # Now create the actual Order
            total_amount = sum([f[1] * random.randint(1, 2) for f in items_to_order])
            
            cursor.execute("""
                INSERT INTO \"Orders\" 
                (\"UserId\", \"OrderDate\", \"TotalAmount\", \"Status\", \"DeliveryAddress\", \"CreatedDate\")
                VALUES (%s, %s, %s, %s, %s, %s) RETURNING \"Id\"
            """, (user_id, order_date, total_amount, "Completed", "123 Test Address, HCM", order_date))
            
            new_order_id = cursor.fetchone()[0]
            
            # Create OrderItems
            for food_id, price in items_to_order:
                qty = random.randint(1, 2)
                cursor.execute("""
                    INSERT INTO \"OrderItems\"
                    (\"OrderId\", \"FoodItemId\", \"Quantity\", \"UnitPrice\", \"CreatedDate\")
                    VALUES (%s, %s, %s, %s, %s)
                """, (new_order_id, food_id, qty, price, order_date))
            
            orders_created += 1

        conn.commit()
        print(f"Successfully generated {orders_created} orders and {logs_created} tracking logs for {user_email}")

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        if conn:
            cursor.close()
            conn.close()

if __name__ == "__main__":
    generate_behavior_data()
