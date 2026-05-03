import grpc
from concurrent import futures
import time
import random
import sys
import os

# Thêm path để import protobuf generated files
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Giả lập import các file protobuf (Cần chạy: python -m grpc_tools.protoc -I../Proto --python_out=. --grpc_python_out=. ../Proto/recommendation.proto)
try:
    import recommendation_pb2
    import recommendation_pb2_grpc
except ImportError:
    print("Vui lòng chạy lệnh compile protoc để sinh ra recommendation_pb2.py và recommendation_pb2_grpc.py")
    sys.exit(1)

class RecommendationServiceServicer(recommendation_pb2_grpc.RecommendationServiceServicer):
    def GetRecommendations(self, request, context):
        print(f"Nhận yêu cầu gRPC từ .NET Client: UserID={request.user_id}, Tọa độ: ({request.lat}, {request.lng})")
        
        # Mô phỏng thuật toán dự đoán của Model SCR (Deep Sequential Model) với tốc độ cao <200ms
        time.sleep(0.05) # Độ trễ 50ms (mô phỏng)
        
        # Logic phân tích vector embedding...
        # Trả về ID các nhà hàng ngẫu nhiên mô phỏng (từ CSDL)
        mock_recommended_ids = random.sample([1, 2, 3], 2)

        reason = f"Gợi ý từ SCR model qua gRPC cho tọa độ {request.lat}, {request.lng}"
        
        # Đảm bảo trả về kiểu int32 và float32 như .proto định nghĩa
        return recommendation_pb2.RecommendationResponse(
            restaurant_ids=mock_recommended_ids,
            reason=reason,
            confidence_score=0.95
        )

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    recommendation_pb2_grpc.add_RecommendationServiceServicer_to_server(RecommendationServiceServicer(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    print("gRPC Python Server đã khởi chạy ở cổng 50051 (Xử lý vector embeddings)...")
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
