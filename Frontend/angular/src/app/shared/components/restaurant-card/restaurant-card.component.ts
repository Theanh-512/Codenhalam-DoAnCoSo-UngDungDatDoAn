import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-restaurant-card',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="group bg-white rounded-2xl overflow-hidden shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 flex flex-col h-full transform hover:-translate-y-1">
      <div class="relative overflow-hidden aspect-video">
        <img [src]="restaurant.imageUrl" [alt]="restaurant.name" 
             class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110">
        <div class="absolute top-3 right-3 bg-white/90 backdrop-blur px-3 py-1 rounded-full text-xs font-bold text-orange-600 shadow-sm">
          ⭐ 4.8 (1.2km)
        </div>
      </div>
      <div class="p-5 flex flex-col flex-grow">
        <h3 class="text-xl font-bold text-gray-800 mb-2 group-hover:text-orange-600 transition-colors">{{ restaurant.name }}</h3>
        <p class="text-gray-500 text-sm line-clamp-2 mb-4 flex-grow">{{ restaurant.description }}</p>
        
        <div class="flex items-center gap-4 text-xs font-semibold text-gray-400 border-t border-gray-50 pt-4 mt-auto">
          <div class="flex items-center gap-1">
            <span>🕒</span> {{ restaurant.openingHours || 'Mở cửa cả ngày' }}
          </div>
          <div class="flex items-center gap-1">
            <span>🛵</span> 15-20 phút
          </div>
        </div>
        
        <button class="w-full mt-4 bg-gray-50 hover:bg-orange-600 hover:text-white text-orange-600 font-bold py-3 px-4 rounded-xl transition-all duration-300 transform active:scale-95 border border-orange-100 hover:border-orange-600 shadow-sm">
          Xem thực đơn
        </button>
      </div>
    </div>
  `,
  styles: []
})
export class RestaurantCardComponent {
  @Input() restaurant: any;
}
