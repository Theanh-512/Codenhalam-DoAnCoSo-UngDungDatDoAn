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
    
    // Giả lập lấy Context hiện tại (User: 1, Tọa độ Lat: 21.0, Lng: 105.8)
    this.aiService.getRecommendations(1, 21.0285, 105.8542).subscribe({
      next: (data) => {
        this.recommendations = data;
        this.isLoading = false;
      },
      error: (err) => {
        this.error = 'Không thể kết nối đến hệ thống AI (Mô hình SCR chưa sẵn sàng).';
        this.isLoading = false;
      }
    });
  }
}
