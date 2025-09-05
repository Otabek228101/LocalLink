
export type LoginRequest = { email: string; password: string };

export type RegisterRequest = {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone: string;
  location: string;
  skills: string;
  availability: string;
};

export type User = {
  id: string;
  email: string;
  first_name?: string | null;
  last_name?: string | null;
  phone?: string | null;
  location?: string | null;
  skills?: string | null;
  availability?: string | null;
  profile_image_url?: string | null;
  rating?: number | null;
  total_jobs_completed?: number | null;
};

export type ListParams = {
  q?: string;
  min_price?: number;
  max_price?: number;
  urgent_only?: boolean;
  distance_km?: number;
  page?: number;
  per_page?: number;
  category?: string;
};

export type Post = {
  id: number;
  title: string;
  description: string;
  category: string;
  post_type: 'job' | 'activities';
  urgency?: 'today' | 'tomorrow' | 'this_week' | null;
  price?: number | null;
  currency?: string | null;
  location?: string | null;
  inserted_at: string;
};

export type CreatePostBody = {
  post: {
    title: string;
    description: string;
    category: string;
    post_type: 'job' | 'activities';
    urgency?: 'today' | 'tomorrow' | 'this_week';
    price?: number;          // отправляем ТОЛЬКО если указана
    currency?: 'UZS' | 'USD' | 'EUR'; // тоже только если есть price
    location?: string;
  };
};

export type ListResponse<T> = {
  data: T[];
  page?: number;
  per_page?: number;
  total?: number;
};

const BASE_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/+$/, '') || 'http://localhost:4000';

function tokenStorage() {
  return {
    saveToken(token: string) {
      try {
        localStorage.setItem('token', token);
      } catch {}
    },
    getToken(): string | null {
      try {
        return localStorage.getItem('token');
      } catch {
        return null;
      }
    },
    removeToken() {
      try {
        localStorage.removeItem('token');
      } catch {}
    },
    isAuthenticated() {
      return !!this.getToken();
    },
  };
}

async function request<T = unknown>(path: string, init?: RequestInit & { auth?: boolean; json?: boolean }) {
  const headers = new Headers();
  headers.set('Content-Type', 'application/json');

  const t = tokenStorage().getToken();
  if (init?.auth && t) headers.set('Authorization', `Bearer ${t}`);

  const res = await fetch(`${BASE_URL}${path}`, {
    ...init,
    headers,
    // credentials по умолчанию не нужны, т.к. JWT в заголовке
    mode: 'cors',
  });

  if (!res.ok) {
    let message = `HTTP ${res.status}`;
    try {
      const data = await res.json();
      message = (data?.error || data?.message || message) as string;
    } catch {}
    throw new Error(message);
  }

  if (init?.json === false) return (await res.text()) as unknown as T;
  try {
    return (await res.json()) as T;
  } catch {
    return undefined as unknown as T;
  }
}

const apiService = {
  ...tokenStorage(),

  async login(body: LoginRequest): Promise<{ token: string; user: User }> {
    return await request('/api/v1/login', {
      method: 'POST',
      body: JSON.stringify(body),
      json: true,
    });
  },

  async register(body: RegisterRequest): Promise<{ token: string; user: User }> {
    // Бэкенд ожидает {"user": {...}}
    return await request('/api/v1/register', {
      method: 'POST',
      body: JSON.stringify({ user: body }),
      json: true,
    });
  },

  async getProfile(): Promise<{ user: User }> {
    return await request('/api/v1/me', { auth: true });
  },

  async listPosts(params?: ListParams): Promise<ListResponse<Post>> {
    const search = new URLSearchParams();
    if (params?.q) search.set('q', params.q);
    if (params?.min_price != null) search.set('min_price', String(params.min_price));
    if (params?.max_price != null) search.set('max_price', String(params.max_price));
    if (params?.urgent_only) search.set('urgent_only', 'true');
    if (params?.distance_km != null) search.set('distance_km', String(params.distance_km));
    if (params?.category) search.set('category', params.category);
    if (params?.page) search.set('page', String(params.page));
    if (params?.per_page) search.set('per_page', String(params.per_page));

    const qs = search.toString();
    return await request(`/api/v1/posts${qs ? `?${qs}` : ''}`, { auth: true });
  },

  async createPost(body: CreatePostBody): Promise<{ post: Post }> {
    return await request('/api/v1/posts', {
      method: 'POST',
      auth: true,
      body: JSON.stringify(body),
      json: true,
    });
  },

  async getConversations(): Promise<Array<{ id: string; title: string; last_message?: string; updated_at?: string }>> {
    try {
      return await request('/api/v1/conversations', { auth: true });
    } catch (e: any) {
      if (String(e?.message || '').includes('404')) return [];
      throw e;
    }
  },
};

function saveToken(token: string) {
  if (typeof window === 'undefined') return;
  localStorage.setItem('token', token);
  window.dispatchEvent(new Event('auth-changed'));
}

function removeToken() {
  if (typeof window === 'undefined') return;
  localStorage.removeItem('token');
  window.dispatchEvent(new Event('auth-changed'));
}

type Category = 'job' | 'task' | 'event' | 'help_needed' | 'social';
type Urgency  = 'now' | 'today' | 'tomorrow' | 'this_week' | 'flexible';
type Currency = 'UZS' | 'USD' | 'EUR';

type PostPayload = {
  title: string;
  description: string;
  category: Category;
  urgency?: Urgency;
  price?: number;
  currency?: Currency | null;
  tags?: string[];
  // обязательные для бэка:
  post_type: 'offer' | 'seeking' | 'event';
  location: string;
  // опционально:
  lat?: number;
  lng?: number;
};
export default apiService;
