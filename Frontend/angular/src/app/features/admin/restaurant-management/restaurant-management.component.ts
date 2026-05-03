import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RestaurantService, Restaurant } from '../../../core/services/restaurant.service';
import { ButtonComponent } from '../../../shared/components/ui/button/button.component';

@Component({
  selector: 'app-restaurant-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ButtonComponent],
  templateUrl: './restaurant-management.component.html',
  styleUrls: ['./restaurant-management.component.css']
})
export class RestaurantManagementComponent implements OnInit {
  restaurants: Restaurant[] = [];
  selectedRestaurant: Restaurant = this.getEmptyRestaurant();
  isEditing = false;
  showForm = false;
  isLoading = false;

  constructor(private restaurantService: RestaurantService) {}

  ngOnInit(): void {
    this.loadRestaurants();
  }

  loadRestaurants() {
    this.isLoading = true;
    this.restaurantService.getAll().subscribe({
      next: (data) => {
        this.restaurants = data;
        this.isLoading = false;
      },
      error: (err) => {
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  getEmptyRestaurant(): Restaurant {
    return {
      name: '',
      description: '',
      address: '',
      imageUrl: '',
      openingHours: '08:00 - 22:00',
      latitude: 21.0,
      longitude: 105.8
    };
  }

  onEdit(restaurant: Restaurant) {
    this.selectedRestaurant = { ...restaurant };
    this.isEditing = true;
    this.showForm = true;
  }

  onDelete(id: number | undefined) {
    if (id && confirm('Bạn có chắc chắn muốn xóa nhà hàng này?')) {
      this.restaurantService.delete(id).subscribe(() => {
        this.loadRestaurants();
      });
    }
  }

  onSubmit() {
    if (this.isEditing && this.selectedRestaurant.id) {
      this.restaurantService.update(this.selectedRestaurant.id, this.selectedRestaurant).subscribe(() => {
        this.resetForm();
        this.loadRestaurants();
      });
    } else {
      this.restaurantService.create(this.selectedRestaurant).subscribe(() => {
        this.resetForm();
        this.loadRestaurants();
      });
    }
  }

  resetForm() {
    this.selectedRestaurant = this.getEmptyRestaurant();
    this.isEditing = false;
    this.showForm = false;
  }
}
