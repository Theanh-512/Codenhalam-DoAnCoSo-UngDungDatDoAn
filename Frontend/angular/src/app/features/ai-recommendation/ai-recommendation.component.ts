import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AiService } from '../../core/services/ai.service';
import { RestaurantCardComponent } from '../../shared/components/restaurant-card/restaurant-card.component';

@Component({
  selector: 'app-ai-recommendation',
  standalone: true,
  imports: [CommonModule, RestaurantCardComponent],
  templateUrl: './ai-recommendation.component.html',
  styleUrls: ['./ai-recommendation.component.css']
})
export class AiRecommendationComponent implements OnInit {
  recommendations: any[] = [];
  isLoading = false;
  error: string | null = null;

  constructor(private aiService: AiService) {}

  ngOnInit(): void {
    this.fetchRecommendations();
  }

  fetchRecommendations() {
    this.isLoading = true;
    this.error = null;
    
    // Ưu tiên lấy gợi ý dựa trên hành vi (Content-Based)
    this.aiService.getBehaviorRecommendations(1).subscribe({
      next: (data) => {
        this.recommendations = data.restaurants;
        this.isLoading = false;
      },
      error: (err) => {
        // Fallback sang gợi ý theo context nếu có lỗi
        this.aiService.getRecommendations(1, 21.0285, 105.8542).subscribe({
          next: (data) => {
            this.recommendations = data;
            this.isLoading = false;
          },
          error: (fallbackErr) => {
            this.error = 'Không thể kết nối đến hệ thống AI (Mô hình SCR và Content-Based chưa sẵn sàng).';
            this.isLoading = false;
          }
        });
      }
    });
  }

}
