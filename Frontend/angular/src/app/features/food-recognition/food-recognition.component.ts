import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-food-recognition',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './food-recognition.component.html',
  styleUrls: ['./food-recognition.component.css']
})
export class FoodRecognitionComponent {
  isAnalyzing = false;
  recognizedFood = '';
  confidence = 0;

  simulateRecognition() {
    this.isAnalyzing = true;
    this.recognizedFood = '';
    
    // Giả lập thời gian máy chủ phân tích Computer Vision (EfficientNetB4)
    setTimeout(() => {
      const mockFoods = ["Phở Bò", "Bún Chả", "Pizza 4P", "Bánh Mì Pate", "Mì Ý Cua"];
      this.recognizedFood = mockFoods[Math.floor(Math.random() * mockFoods.length)];
      this.confidence = 85 + Math.random() * 14; 
      this.isAnalyzing = false;
    }, 2000);
  }
}
