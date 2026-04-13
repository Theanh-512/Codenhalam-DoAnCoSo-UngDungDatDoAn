import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { FoodItem, Category } from '../models/food.model';

@Injectable({
    providedIn: 'root'
})
export class FoodService {
    private apiUrl = 'https://localhost:7001/api'; // Temporary URL

    constructor(private http: HttpClient) { }

    // Placeholder methods for now
    getFoodItems(): Observable<FoodItem[]> {
        return of([]);
    }

    getCategories(): Observable<Category[]> {
        return of([]);
    }
}
