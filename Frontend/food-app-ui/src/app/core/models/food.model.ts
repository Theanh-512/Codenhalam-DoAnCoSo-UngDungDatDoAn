export interface BaseEntity {
    id: number;
    createdDate: Date;
    updatedDate?: Date;
}

export interface FoodItem extends BaseEntity {
    name: string;
    description: string;
    price: number;
    imageUrl: string;
    isAvailable: boolean;
    categoryId: number;
}

export interface Category extends BaseEntity {
    name: string;
    description: string;
    foodItems?: FoodItem[];
}
