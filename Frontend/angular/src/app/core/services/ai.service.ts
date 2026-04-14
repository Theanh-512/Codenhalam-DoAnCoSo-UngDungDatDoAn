import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AiService {
  private apiUrl = 'http://localhost:5149/api'; // .NET Backend API

  constructor(private http: HttpClient) {}

  // Phân tích ảnh món ăn (Computer Vision)
  recognizeFood(imageFile: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', imageFile);
    // Trong thực tế, gọi sang API AI Python hoặc C# trung gian
    return this.http.post(`${this.apiUrl}/Food/recognize`, formData);
  }

  // Lấy gợi ý dựa vào Context (SCR Model)
  getRecommendations(userId: number, lat: number, lng: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/Restaurants/recommend?userId=${userId}&lat=${lat}&lng=${lng}`);
  }
}
