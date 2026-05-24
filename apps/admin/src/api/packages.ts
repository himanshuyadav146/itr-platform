import apiClient from './client';
import { API_ENDPOINTS } from './endpoints';
import type { Package, PackageFormPayload } from '../types/package';
import type { ApiResponse } from '../types/api';

function normalizePackage(raw: Record<string, unknown>): Package {
  return {
    id: Number(raw.id),
    packagename: String(raw.packagename ?? raw.package_name ?? ''),
    price: Number(raw.price ?? 0),
    description1: String(raw.description1 ?? raw.description ?? ''),
    turnover: String(raw.turnover ?? ''),
    icon: String(raw.icon ?? ''),
    color: String(raw.color ?? ''),
    isActive: raw.isActive !== undefined ? Number(raw.isActive) : raw.is_active !== undefined ? Number(raw.is_active) : 1,
    createdAt: raw.createdAt != null ? String(raw.createdAt) : raw.created_at != null ? String(raw.created_at) : undefined,
    updatedAt: raw.updatedAt != null ? String(raw.updatedAt) : raw.updated_at != null ? String(raw.updated_at) : undefined,
  };
}

export const packagesApi = {
  getPackages: async (): Promise<Package[]> => {
    const response = await apiClient.get<unknown>(API_ENDPOINTS.PACKAGES);
    const body = response.data;
    let list: unknown[] = [];
    if (Array.isArray(body)) list = body;
    else if (body && typeof body === 'object' && 'data' in body) {
      const data = (body as { data: unknown }).data;
      list = Array.isArray(data) ? data : (data && typeof data === 'object' && 'packages' in data)
        ? ((data as { packages: unknown[] }).packages ?? [])
        : [];
    } else if (body && typeof body === 'object' && 'packages' in body) {
      list = (body as { packages: unknown[] }).packages ?? [];
    }
    if (!Array.isArray(list)) list = [];
    return list.map((item) => normalizePackage(item as Record<string, unknown>));
  },

  addPackage: async (payload: PackageFormPayload): Promise<Package> => {
    const response = await apiClient.post<ApiResponse<Package>>(API_ENDPOINTS.PACKAGE_ADD, payload);
    const data = response.data?.data;
    if (data && typeof data === 'object') return normalizePackage(data as unknown as Record<string, unknown>);
    return normalizePackage((response.data as unknown) as Record<string, unknown>);
  },

  updatePackage: async (payload: PackageFormPayload & { id: number }): Promise<Package> => {
    const response = await apiClient.post<ApiResponse<Package>>(API_ENDPOINTS.PACKAGE_ADD, payload);
    const data = response.data?.data;
    if (data && typeof data === 'object') return normalizePackage(data as unknown as Record<string, unknown>);
    return normalizePackage((response.data as unknown) as Record<string, unknown>);
  },

  deletePackage: async (id: number): Promise<void> => {
    await apiClient.post<ApiResponse>(API_ENDPOINTS.PACKAGE_DELETE, { id });
  },
};
