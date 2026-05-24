export interface Package {
  id: number;
  packagename: string;
  price: number;
  description1: string;
  turnover: string;
  icon: string;
  color: string;
  isActive: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface PackageFormPayload {
  id?: number;
  packagename: string;
  price: number;
  description1: string;
  turnover: string;
  icon: string;
  color: string;
  isActive: number;
}
