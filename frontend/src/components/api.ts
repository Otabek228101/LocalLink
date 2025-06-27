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
    user: {
      id: string;
      first_name: string;
      last_name: string;
      rating?: number;
    };
  }
