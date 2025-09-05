// Базовые типы под наш фронт (согласованы с твоим беком)
export type UUID = string;

export type User = {
  id: UUID;
  email: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  location?: string;
  skills?: string;
  availability?: string;
  is_verified?: boolean;
  profile_image_url?: string | null; // бек может вернуть null
  rating?: number | null;
  total_jobs_completed?: number | null;
};

export type Category = "job" | "activities";
export type Urgency = "today" | "tomorrow" | "this_week";
export type Currency = "UZS" | "USD" | "EUR";

export type Coordinates = {
  lat: number;
  lng: number;
};

export type Post = {
  id: string | number;
  title: string;
  description?: string | null;
  category: Category;
  urgency?: Urgency | null;
  price?: number | null;
  currency?: Currency | null;
};
export type PostPayload = {
  title: string;
  description: string;
  category: Category;
  urgency: Urgency;
  price: number | null;
  currency?: Currency;
};

export type PostFilters = {
  q: string;
  urgentOnly: boolean;
  priceMin?: number;
  priceMax?: number;
  distanceKm?: number; // клиентский фильтр
  category?: string | null;
};

