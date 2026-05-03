import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { StatCardComponent } from '../../../shared/components/ui/stat-card/stat-card.component';
import { RestaurantService } from '../../../core/services/restaurant.service';
import { UserService } from '../../../core/services/user.service';
import { OrderService } from '../../../core/services/order.service';
import { forkJoin } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink, StatCardComponent],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  restaurantCount = 0;
  userCount = 0;
  orderCount = 0;
  totalRevenue = 54200000; // Mock revenue for display
  isLoading = true;

  constructor(
    private restaurantService: RestaurantService,
    private userService: UserService,
    private orderService: OrderService
  ) {}

  ngOnInit(): void {
    this.loadStats();
  }

  loadStats() {
    this.isLoading = true;
    forkJoin({
      restaurants: this.restaurantService.getAll(),
      users: this.userService.getAll(),
      orders: this.orderService.getAll()
    }).subscribe({
      next: (results) => {
        this.restaurantCount = results.restaurants.length;
        this.userCount = results.users.length;
        this.orderCount = results.orders.length;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error loading dashboard stats:', err);
        this.isLoading = false;
      }
    });
  }
}
