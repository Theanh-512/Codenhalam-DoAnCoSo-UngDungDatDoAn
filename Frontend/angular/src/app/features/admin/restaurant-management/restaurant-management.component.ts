import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RestaurantService, Restaurant, FoodItem } from '../../../core/services/restaurant.service';
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
  currentRestaurant: Restaurant = this.getEmptyRestaurant();
  isEditMode = false;
  showModal = false;
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
      longitude: 105.8,
      isActive: true
    };
  }

  openAddModal() {
    this.currentRestaurant = this.getEmptyRestaurant();
    this.isEditMode = false;
    this.showModal = true;
  }

  editRestaurant(restaurant: Restaurant) {
    this.currentRestaurant = { ...restaurant };
    this.isEditMode = true;
    this.showModal = true;
  }

  deleteRestaurant(id: number | undefined) {
    if (id && confirm('Bạn có chắc chắn muốn xóa nhà hàng này?')) {
      this.restaurantService.delete(id).subscribe(() => {
        this.loadRestaurants();
      });
    }
  }

  saveRestaurant() {
    if (this.isEditMode && this.currentRestaurant.id) {
      this.restaurantService.update(this.currentRestaurant.id, this.currentRestaurant).subscribe(() => {
        this.closeModal();
        this.loadRestaurants();
      });
    } else {
      this.restaurantService.create(this.currentRestaurant).subscribe(() => {
        this.closeModal();
        this.loadRestaurants();
      });
    }
  }

  closeModal() {
    this.currentRestaurant = this.getEmptyRestaurant();
    this.isEditMode = false;
    this.showModal = false;
  }

  // ---- Menu Management ----
  showMenuModal = false;
  currentMenu: FoodItem[] = [];
  newFoodItem: FoodItem = this.getEmptyFoodItem();
  selectedRestaurantId?: number;

  getEmptyFoodItem(): FoodItem {
    return { name: '', description: '', price: 0, imageUrl: '', rating: 5.0 };
  }

  openMenuModal(res: Restaurant) {
    if (!res.id) return;
    this.selectedRestaurantId = res.id;
    this.showMenuModal = true;
    this.loadMenu(res.id);
  }

  loadMenu(id: number) {
    this.restaurantService.getMenu(id).subscribe({
      next: (data) => this.currentMenu = data,
      error: () => this.currentMenu = []
    });
  }

  addFoodItem() {
    if (this.selectedRestaurantId && this.newFoodItem.name) {
      this.restaurantService.addMenuItem(this.selectedRestaurantId, this.newFoodItem).subscribe(() => {
        this.loadMenu(this.selectedRestaurantId!);
        this.newFoodItem = this.getEmptyFoodItem();
      });
    }
  }

  closeMenuModal() {
    this.showMenuModal = false;
    this.currentMenu = [];
    this.newFoodItem = this.getEmptyFoodItem();
  }
}

