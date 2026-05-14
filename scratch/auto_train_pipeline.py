import subprocess
import time
import os

def run_step(name, cmd):
    print(f"--- STARTING STEP: {name} ---")
    start = time.time()
    # Chạy lệnh và đợi
    process = subprocess.Popen(cmd, shell=True)
    process.wait()
    end = time.time()
    print(f"--- COMPLETED STEP: {name} ({round(end-start, 2)}s) ---")
    if process.returncode != 0:
        print(f"❌ Step {name} FAILED with code {process.returncode}")
        return False
    return True

def main():
    # Bước 1: Đợi Seeder (nếu đang chạy bên ngoài) hoặc giả định đã xong phần lớn
    # Ở đây chúng ta sẽ chạy generate_training_logs.py
    if not run_step("Generate Synthetic Logs", "python scratch/generate_training_logs.py"):
        return

    # Bước 2: Export dữ liệu ra CSV cho Trainer
    print("--- Exporting TrackingLogs to interactions.csv ---")
    import psycopg2
    import csv
    
    conn_str = "host=aws-1-ap-southeast-2.pooler.supabase.com port=5432 dbname=postgres user=postgres.wbusmwbzqlkyhxtoghsl password=Codenhalam123456 sslmode=require"
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()
    
    # Query logs join FoodItems for image paths
    query = '''
        SELECT t."UserId", t."FoodItemId", t."Timestamp", t."Latitude", t."Longitude", f."ImageUrl"
        FROM "TrackingLogs" t
        LEFT JOIN "FoodItems" f ON t."FoodItemId" = f."Id"
        WHERE t."FoodItemId" IS NOT NULL
        ORDER BY t."Timestamp"
    '''
    cur.execute(query)
    rows = cur.fetchall()
    
    csv_path = "AIEngine/data/interactions.csv"
    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['user_id', 'item_id', 'timestamp', 'lat', 'lon', 'image_path'])
        for r in rows:
            # Format timestamp to ISO
            ts_str = r[2].strftime("%Y-%m-%dT%H:%M:%S")
            writer.writerow([r[0], r[1], ts_str, r[3], r[4], r[5]])
            
    print(f"Exported {len(rows)} records to {csv_path}")
    cur.close()
    conn.close()

    # Bước 3: Chạy Training
    # Chuyển Cwd sang AIEngine để imports hoạt động
    os.chdir("AIEngine")
    run_step("Model Training", "python train_real_data.py")
    os.chdir("..")

    print("=== PIPELINE COMPLETED SUCCESSFULLY ===")

if __name__ == "__main__":
    main()
