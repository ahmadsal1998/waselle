export interface OrderCategory {
  _id: string;
  name: string;
  description?: string;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface OrderCategoryForm {
  name: string;
  description: string;
}


