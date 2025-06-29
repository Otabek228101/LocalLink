// lib/api-config.ts
export const API_CONFIG = {
  BASE_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1',
  TIMEOUT: 30000,
  RETRY_ATTEMPTS: 3,
};

export interface AppUser {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  location?: {
    lat: number;
    lng: number;
    address: string;
  };
  skills?: string[];
  rating?: number;
  verified?: boolean;
  total_jobs_completed?: number;
}

export interface Post {
  id: string;
  title: string;
  description: string;
  category: string;
  post_type: string;
  urgency: string;
  price?: number;
  currency?: string;
  location: string;
  skills_required?: string[];
  max_distance_km?: number;
  is_active: boolean;
  expires_at?: string;
  images?: string;
  contact_preference: string;
  inserted_at: string;
  updated_at: string;
  user: {
    id: string;
    first_name: string;
    last_name: string;
    rating?: number;
    total_jobs_completed?: number;
  };
}

export interface ApiResponse<T> {
  data?: T;
  message?: string;
  error?: string;
  errors?: Record<string, string[]>;
}

// API client class
export class ApiClient {
  private baseUrl: string;
  private timeout: number;

  constructor() {
    this.baseUrl = API_CONFIG.BASE_URL;
    this.timeout = API_CONFIG.TIMEOUT;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${endpoint}`;
    const token = localStorage.getItem('token');

    const config: RequestInit = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        return { error: data.error || 'Request failed', errors: data.errors };
      }

      return { data };
    } catch (error) {
      console.error('API request failed:', error);
      return { error: 'Network error occurred' };
    }
  }

  // Auth methods
  async login(email: string, password: string) {
    return this.request<{ token: string; user: AppUser }>('/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
  }

  async register(userData: {
    first_name: string;
    last_name: string;
    email: string;
    password: string;
    phone?: string;
  }) {
    return this.request<{ token: string; user: AppUser }>('/register', {
      method: 'POST',
      body: JSON.stringify({ user: userData }),
    });
  }

  async getProfile() {
    return this.request<{ user: AppUser }>('/me');
  }

  // Posts methods
  async getPosts(filters?: {
    category?: string;
    location?: string;
    active?: boolean;
  }) {
    const params = new URLSearchParams();
    if (filters?.category) params.append('category', filters.category);
    if (filters?.location) params.append('location', filters.location);
    if (filters?.active !== undefined) params.append('active', filters.active.toString());

    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request<{ posts: Post[] }>(`/posts${query}`);
  }

  async getPost(id: string) {
    return this.request<{ post: Post }>(`/posts/${id}`);
  }

  async createPost(postData: {
    title: string;
    description: string;
    category: string;
    post_type: string;
    urgency: string;
    location: string;
    price?: number;
    currency?: string;
    skills_required?: string;
  }) {
    return this.request<{ post: Post }>('/posts', {
      method: 'POST',
      body: JSON.stringify({ post: postData }),
    });
  }

  async updatePost(id: string, postData: Partial<Post>) {
    return this.request<{ post: Post }>(`/posts/${id}`, {
      method: 'PUT',
      body: JSON.stringify({ post: postData }),
    });
  }

  async deletePost(id: string) {
    return this.request<{ message: string }>(`/posts/${id}`, {
      method: 'DELETE',
    });
  }

  async getMyPosts() {
    return this.request<{ posts: Post[] }>('/my-posts');
  }
}

// Export singleton instance
export const apiClient = new ApiClient();