import { ComponentFixture, TestBed } from '@angular/core/testing';

import { FoodRecognitionComponent } from './food-recognition.component';

describe('FoodRecognitionComponent', () => {
  let component: FoodRecognitionComponent;
  let fixture: ComponentFixture<FoodRecognitionComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [FoodRecognitionComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(FoodRecognitionComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
