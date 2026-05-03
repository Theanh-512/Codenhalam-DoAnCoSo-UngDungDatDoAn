import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-ui-button',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button 
      [type]="type"
      [disabled]="disabled || isLoading"
      (click)="onClick.emit($event)"
      [class]="getClasses()"
    >
      <span *ngIf="isLoading" class="mr-2 animate-spin">🌀</span>
      <ng-content></ng-content>
    </button>
  `,
})
export class ButtonComponent {
  @Input() type: 'button' | 'submit' = 'button';
  @Input() variant: 'primary' | 'secondary' | 'danger' | 'outline' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() disabled = false;
  @Input() isLoading = false;
  @Input() fullWidth = false;
  
  @Output() onClick = new EventEmitter<MouseEvent>();

  getClasses() {
    const base = 'inline-flex items-center justify-center font-bold transition-all duration-200 active:scale-95 disabled:opacity-50 disabled:pointer-events-none rounded-xl';
    
    const variants = {
      primary: 'bg-orange-600 text-white hover:bg-orange-700 shadow-md hover:shadow-orange-200',
      secondary: 'bg-gray-900 text-white hover:bg-black',
      danger: 'bg-red-500 text-white hover:bg-red-600',
      outline: 'bg-transparent border-2 border-orange-600 text-orange-600 hover:bg-orange-50'
    };

    const sizes = {
      sm: 'px-3 py-1 text-xs',
      md: 'px-6 py-3 text-sm',
      lg: 'px-8 py-4 text-base'
    };

    return `${base} ${variants[this.variant]} ${sizes[this.size]} ${this.fullWidth ? 'w-full' : ''}`;
  }
}
