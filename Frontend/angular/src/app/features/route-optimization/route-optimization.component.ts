import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OrderService } from '../../core/services/order.service';

@Component({
  selector: 'app-route-optimization',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './route-optimization.component.html',
  styleUrls: ['./route-optimization.component.css']
})
export class RouteOptimizationComponent {
  optimizationData: any = null;
  isLoading = false;
  error: string | null = null;

  constructor(private orderService: OrderService) {}

  runOptimization() {
    this.isLoading = true;
    this.error = null;
    this.optimizationData = null;

    this.orderService.getOptimizedRoute().subscribe({
      next: (data) => {
        this.optimizationData = data;
        this.isLoading = false;
      },
      error: (err) => {
        this.error = 'Không thể lấy dữ liệu lộ trình từ máy chủ.';
        this.isLoading = false;
      }
    });
  }
}
