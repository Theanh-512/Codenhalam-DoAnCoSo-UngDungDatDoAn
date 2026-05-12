import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {
  activeCategory = 'Food';
  activeTab = 'Home';
  searchQuery = '';

  categories = [
    { name: 'Drinks', icon: '🥤' },
    { name: 'Food', icon: '🍗' },
    { name: 'Cake', icon: '🧁' },
    { name: 'Snack', icon: '🍟' }
  ];

  foodMenus = [
    { name: 'Burgers', bg: '#eef5ef', img: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=200&q=80' },
    { name: 'Pizza', bg: '#fff7e6', img: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=200&q=80' },
    { name: 'BBQ', bg: '#f2eff8', img: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?auto=format&fit=crop&w=200&q=80' },
    { name: 'Fruit', bg: '#fbece1', img: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=200&q=80' },
    { name: 'Sushi', bg: '#e6f4f8', img: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=200&q=80' },
    { name: 'Noodle', bg: '#eff7ed', img: 'https://images.unsplash.com/photo-1585032226651-759b368d7246?auto=format&fit=crop&w=200&q=80' }
  ];

  restaurants = [
    { 
      name: 'Awesome Fruit Restaurant', 
      address: '13th Street. 47 W 13th St, NY', 
      distance: '3 min • 1.1 km', 
      rating: 4.6, 
      img: 'https://images.unsplash.com/photo-1490818387583-1b5ba4597d62?auto=format&fit=crop&w=200&q=80' 
    },
    { 
      name: 'Pizza Lover Company', 
      address: '78th Street. 88 W 21th St, NY', 
      distance: '4 min • 1.5 km', 
      rating: 4.9, 
      img: 'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?auto=format&fit=crop&w=200&q=80' 
    },
    { 
      name: 'King Burger & BBQ', 
      address: '42nd Avenue. 12 E 14th St, NY', 
      distance: '6 min • 2.3 km', 
      rating: 4.7, 
      img: 'https://images.unsplash.com/photo-1586816001966-79b736744398?auto=format&fit=crop&w=200&q=80' 
    }
  ];

  constructor(private authService: AuthService, private router: Router) {}

  ngOnInit(): void {}

  setCategory(category: string) {
    this.activeCategory = category;
  }

  setTab(tab: string) {
    this.activeTab = tab;
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }

  selectFood(name: string) {
    alert(`Đã chọn xem chi tiết danh mục món ăn: ${name}\nHệ thống đang chuẩn bị gợi ý các quán bán ${name} ngon nhất!`);
  }

  selectRestaurant(name: string) {
    alert(`Đã chọn nhà hàng: ${name}\nTính năng Menu chi tiết sẽ sớm được cập nhật!`);
    this.setTab('Order'); // Simulate moving to order tab
  }

  get filteredRestaurants() {
    if (!this.searchQuery) {
      return this.restaurants;
    }
    const q = this.searchQuery.toLowerCase();
    return this.restaurants.filter(r => r.name.toLowerCase().includes(q) || r.address.toLowerCase().includes(q));
  }

  get filteredFoodMenus() {
    if (!this.searchQuery) {
      return this.foodMenus;
    }
    const q = this.searchQuery.toLowerCase();
    return this.foodMenus.filter(f => f.name.toLowerCase().includes(q));
  }
}
