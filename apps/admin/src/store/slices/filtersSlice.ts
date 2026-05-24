import { createSlice, type PayloadAction } from '@reduxjs/toolkit';
import type { UserFilters, ITRFilters } from '../../types';

interface FiltersState {
  userFilters: UserFilters;
  itrFilters: ITRFilters;
}

const initialState: FiltersState = {
  userFilters: {
    page: 1,
    limit: 10,
  },
  itrFilters: {
    page: 1,
    limit: 10,
  },
};

const filtersSlice = createSlice({
  name: 'filters',
  initialState,
  reducers: {
    setUserFilters: (state, action: PayloadAction<Partial<UserFilters>>) => {
      state.userFilters = { ...state.userFilters, ...action.payload };
    },
    setITRFilters: (state, action: PayloadAction<Partial<ITRFilters>>) => {
      state.itrFilters = { ...state.itrFilters, ...action.payload };
    },
    clearUserFilters: (state) => {
      state.userFilters = { page: 1, limit: 10 };
    },
    clearITRFilters: (state) => {
      state.itrFilters = { page: 1, limit: 10 };
    },
    clearAllFilters: (state) => {
      state.userFilters = { page: 1, limit: 10 };
      state.itrFilters = { page: 1, limit: 10 };
    },
  },
});

export const {
  setUserFilters,
  setITRFilters,
  clearUserFilters,
  clearITRFilters,
  clearAllFilters,
} = filtersSlice.actions;
export default filtersSlice.reducer;

