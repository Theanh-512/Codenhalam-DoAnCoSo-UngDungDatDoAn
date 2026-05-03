import { Routes } from '@angular/router';
import { LoginComponent } from './features/login/login.component';
import { DashboardComponent } from './features/admin/dashboard/dashboard.component';
import { RestaurantManagementComponent } from './features/admin/restaurant-management/restaurant-management.component';
import { UserManagementComponent } from './features/admin/user-management/user-management.component';
import { OrderManagementComponent } from './features/admin/order-management/order-management.component';
import { AiRecommendationComponent } from './features/ai-recommendation/ai-recommendation.component';
import { FoodRecognitionComponent } from './features/food-recognition/food-recognition.component';
import { RouteOptimizationComponent } from './features/route-optimization/route-optimization.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'admin/dashboard', component: DashboardComponent },
  { path: 'admin/restaurants', component: RestaurantManagementComponent },
  { path: 'admin/users', component: UserManagementComponent },
  { path: 'admin/orders', component: OrderManagementComponent },
  { path: 'ai-recommendation', component: AiRecommendationComponent },
  { path: 'food-recognition', component: FoodRecognitionComponent },
  { path: 'route-optimization', component: RouteOptimizationComponent },
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: '**', redirectTo: '/login' }
];
