import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-ui-button',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './button.component.html',
  styleUrls: ['./button.component.css']
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
    return {
      'btn': true,
      [`btn-${this.variant}`]: true,
      [`btn-${this.size}`]: true,
      'w-full': this.fullWidth,
      'isLoading': this.isLoading
    };
  }
}
