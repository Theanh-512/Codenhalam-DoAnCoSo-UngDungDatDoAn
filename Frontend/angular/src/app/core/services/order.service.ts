import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class OrderService {
  private apiUrl = 'http://localhost:5149/api';

  constructor(private http: HttpClient) {}

  // Lấy lộ trình giao hàng tối ưu (Greedy Algorithm)
  getOptimizedRoute(): Observable<any> {
    return this.http.get(`${this.apiUrl}/Orders/optimize-route`);
  }
}
