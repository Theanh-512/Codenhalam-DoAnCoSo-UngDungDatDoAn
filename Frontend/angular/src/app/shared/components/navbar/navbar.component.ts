import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  template: `
    <nav class="bg-gray-900 text-white p-4 shadow-lg sticky top-0 z-50">
      <div class="container mx-auto flex justify-between items-center">
        <div class="text-2xl font-bold flex items-center gap-2 tracking-tight cursor-pointer" routerLink="/">
          <span class="bg-orange-600 p-2 rounded-lg">🍔</span> 
          <span class="bg-gradient-to-r from-white to-gray-400 bg-clip-text text-transparent">M-CARS Food</span>
        </div>
        
        <div class="hidden md:flex space-x-8" *ngIf="authService.currentUser$ | async as user">
          <!-- Client Links -->
          <ng-container *ngIf="user.role === 'user'">
            <a routerLink="/ai-recommendation" routerLinkActive="text-orange-500 font-bold border-b-2 border-orange-500" 
               class="transition-all duration-200 hover:text-orange-400 pb-1">🧠 Gợi ý AI</a>
            <a routerLink="/food-recognition" routerLinkActive="text-orange-500 font-bold border-b-2 border-orange-500" 
               class="transition-all duration-200 hover:text-orange-400 pb-1">📷 Nhận diện Món</a>
          </ng-container>

          <!-- Admin Links -->
          <ng-container *ngIf="user.role === 'admin'">
            <a routerLink="/admin/dashboard" routerLinkActive="text-orange-500 font-bold border-b-2 border-orange-500" 
               class="transition-all duration-200 hover:text-orange-400 pb-1">📊 Dashboard</a>
            <a routerLink="/admin/restaurants" routerLinkActive="text-orange-500 font-bold border-b-2 border-orange-500" 
               class="transition-all duration-200 hover:text-orange-400 pb-1">🏪 Nhà hàng</a>
            <a routerLink="/route-optimization" routerLinkActive="text-orange-500 font-bold border-b-2 border-orange-500" 
               class="transition-all duration-200 hover:text-orange-400 pb-1">🗺️ Tối ưu Lộ trình</a>
          </ng-container>
        </div>

        <div class="flex items-center gap-4">
            <ng-container *ngIf="authService.currentUser$ | async as user; else loginBtn">
                <span class="text-xs font-bold text-gray-400 hidden sm:inline">{{ user.email }} ({{ user.role }})</span>
                <button (click)="logout()" class="bg-gray-800 hover:bg-gray-700 text-white px-4 py-2 rounded-xl text-xs font-bold transition-all transform active:scale-95 border border-gray-700">
                    Đăng xuất
                </button>
            </ng-container>
            <ng-template #loginBtn>
                <button routerLink="/login" class="bg-orange-600 hover:bg-orange-700 text-white px-6 py-2 rounded-full text-sm font-bold transition-all transform active:scale-95 shadow-md">
                    Đăng nhập
                </button>
            </ng-template>
        </div>
      </div>
    </nav>
  `,
  styles: []
})
export class NavbarComponent {
  constructor(public authService: AuthService, private router: Router) {}

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
