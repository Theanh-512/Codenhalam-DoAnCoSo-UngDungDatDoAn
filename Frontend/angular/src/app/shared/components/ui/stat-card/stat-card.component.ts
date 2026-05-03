import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-stat-card',
  standalone: true,
  imports: [CommonModule, RouterLink],
  template: `
    <div [routerLink]="link" class="bg-white p-8 rounded-[2rem] border border-gray-100 shadow-sm hover:shadow-xl transition-all duration-300 cursor-pointer group">
      <div class="flex items-center justify-between mb-4">
        <span [class]="color + ' w-12 h-12 rounded-2xl flex items-center justify-center text-2xl shadow-inner group-hover:scale-110 transition-transform'">
          {{ icon }}
        </span>
        <span class="text-[10px] font-black text-gray-300 uppercase tracking-widest">Detail →</span>
      </div>
      <p class="text-gray-500 text-sm font-semibold mb-1">{{ label }}</p>
      <h3 class="text-3xl font-black text-gray-900 tracking-tight">{{ value }}</h3>
    </div>
  `,
})
export class StatCardComponent {
  @Input() label = '';
  @Input() value: string | number = '';
  @Input() icon = '';
  @Input() color = '';
  @Input() link = '';
}
