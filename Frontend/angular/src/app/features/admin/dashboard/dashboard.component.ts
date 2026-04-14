import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  stats = [
    { label: 'Tổng Nhà hàng', value: '12', icon: '🏪', color: 'bg-blue-100 text-blue-600' },
    { label: 'Đơn hàng mới', value: '48', icon: '📝', color: 'bg-green-100 text-green-600' },
    { label: 'Người dùng', value: '156', icon: '👥', color: 'bg-purple-100 text-purple-600' },
    { label: 'Doanh thu', value: '45.2tr', icon: '💰', color: 'bg-orange-100 text-orange-600' }
  ];

  constructor() {}

  ngOnInit(): void {}
}
