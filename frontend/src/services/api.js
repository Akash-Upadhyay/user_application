import axios from 'axios';

// Base URL for API requests
const API_URL = process.env.REACT_APP_API_URL || '/api';

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add a request interceptor to attach the token to every request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Auth Service
export const authService = {
  register: (userData) => api.post('/auth/register', userData),
  login: (email, password) => api.post('/auth/token', new URLSearchParams({
    username: email,
    password: password
  }), {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  }),
  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  }
};

// User Service
export const userService = {
  getProfile: () => api.get('/users/profiles/me'),
  createProfile: (profile) => api.post('/users/profiles', profile),
  updateProfile: (profile) => api.put('/users/profiles/me', profile),
  getProfileById: (id) => api.get(`/users/profiles/${id}`)
};

// Analytics Service
export const analyticsService = {
  trackEvent: (eventData) => api.post('/analytics/track', eventData),
  getEvents: (eventType, limit) => {
    let url = '/analytics/events';
    const params = {};
    if (eventType) params.event_type = eventType;
    if (limit) params.limit = limit;
    
    return api.get(url, { params });
  },
  getSummary: () => api.get('/analytics/summary'),
  clearEvents: () => api.delete('/analytics/events')
};

// Track page views automatically
export const trackPageView = (path, userId) => {
  try {
    analyticsService.trackEvent({
      user_id: userId,
      event_type: 'page_view',
      event_data: { path }
    });
  } catch (error) {
    console.error('Failed to track page view:', error);
  }
};

export default api; 