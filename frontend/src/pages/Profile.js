import React, { useState, useEffect } from 'react';
import { useAuth } from '../services/AuthContext';
import { userService } from '../services/api';

const Profile = () => {
  const { user } = useAuth();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    bio: ''
  });
  const [isSaving, setIsSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [debugInfo, setDebugInfo] = useState(null);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Debug info
      const token = localStorage.getItem('token');
      setDebugInfo(`Token exists: ${!!token}`);
      console.log("Fetching profile with token:", token);
      
      const response = await userService.getProfile();
      setProfile(response.data);
      setFormData({
        name: response.data.name,
        bio: response.data.bio || ''
      });
    } catch (error) {
      console.error("Profile fetch error:", error);
      setDebugInfo(`Error: ${error.message}, Status: ${error.response?.status}, Data: ${JSON.stringify(error.response?.data)}`);
      
      if (error.response && error.response.status === 404) {
        // Profile doesn't exist yet, set to editing mode to create one
        setIsEditing(true);
      } else if (error.response && error.response.status === 401) {
        setError('Authentication failed. Please logout and login again.');
      } else {
        setError('Failed to load profile');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSaving(true);
    setDebugInfo(null);
    
    try {
      const token = localStorage.getItem('token');
      console.log("Creating/updating profile with token:", token);
      
      let response;
      if (profile) {
        response = await userService.updateProfile(formData);
      } else {
        response = await userService.createProfile(formData);
      }
      
      setProfile(response.data);
      setIsEditing(false);
      setSuccess(true);
      
      setTimeout(() => {
        setSuccess(false);
      }, 3000);
    } catch (error) {
      console.error("Profile save error:", error);
      setDebugInfo(`Save Error: ${error.message}, Status: ${error.response?.status}, Data: ${JSON.stringify(error.response?.data)}`);
      
      if (error.response && error.response.status === 401) {
        setError('Authentication failed. Please logout and login again.');
      } else {
        setError('Failed to save profile');
      }
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="container py-5 text-center">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
        <p className="mt-3">Loading profile...</p>
      </div>
    );
  }

  return (
    <div className="container py-5">
      <div className="row justify-content-center">
        <div className="col-md-8">
          <div className="card shadow">
            <div className="card-body p-4">
              <div className="d-flex justify-content-between align-items-center mb-4">
                <h2 className="card-title mb-0">
                  {isEditing ? 'Edit Profile' : 'User Profile'}
                </h2>
                {!isEditing && profile && (
                  <button
                    className="btn btn-outline-primary"
                    onClick={() => setIsEditing(true)}
                  >
                    Edit Profile
                  </button>
                )}
              </div>

              {error && (
                <div className="alert alert-danger" role="alert">
                  {error}
                </div>
              )}

              {success && (
                <div className="alert alert-success" role="alert">
                  Profile saved successfully!
                </div>
              )}

              {debugInfo && (
                <div className="alert alert-warning" role="alert">
                  <small>{debugInfo}</small>
                </div>
              )}

              {isEditing ? (
                <form onSubmit={handleSubmit}>
                  <div className="mb-3">
                    <label htmlFor="name" className="form-label">Name</label>
                    <input
                      type="text"
                      className="form-control"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                    />
                  </div>
                  
                  <div className="mb-3">
                    <label htmlFor="bio" className="form-label">Bio</label>
                    <textarea
                      className="form-control"
                      id="bio"
                      name="bio"
                      rows="4"
                      value={formData.bio}
                      onChange={handleChange}
                    ></textarea>
                  </div>
                  
                  <div className="d-flex gap-2">
                    <button
                      type="submit"
                      className="btn btn-primary"
                      disabled={isSaving}
                    >
                      {isSaving ? 'Saving...' : 'Save Profile'}
                    </button>
                    {profile && (
                      <button
                        type="button"
                        className="btn btn-outline-secondary"
                        onClick={() => {
                          setIsEditing(false);
                          setFormData({
                            name: profile.name,
                            bio: profile.bio || ''
                          });
                        }}
                      >
                        Cancel
                      </button>
                    )}
                  </div>
                </form>
              ) : profile ? (
                <div>
                  <div className="mb-4">
                    <h5>Email</h5>
                    <p className="text-muted">{user.email}</p>
                  </div>
                  
                  <div className="mb-4">
                    <h5>Name</h5>
                    <p>{profile.name}</p>
                  </div>
                  
                  {profile.bio && (
                    <div className="mb-4">
                      <h5>Bio</h5>
                      <p>{profile.bio}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="text-center py-4">
                  <p>You haven't created a profile yet.</p>
                  <button
                    className="btn btn-primary"
                    onClick={() => setIsEditing(true)}
                  >
                    Create Profile
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile; 