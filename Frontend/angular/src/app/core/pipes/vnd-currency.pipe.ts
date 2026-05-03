import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'vndCurrency',
  standalone: true
})
export class VndCurrencyPipe implements PipeTransform {
  transform(value: number | string | null): string {
    if (value === null || value === undefined) return '0 đ';
    
    const amount = typeof value === 'string' ? parseFloat(value) : value;
    
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(amount);
  }
}
