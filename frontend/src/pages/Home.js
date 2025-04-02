import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../services/AuthContext';

const Home = () => {
  const { isAuthenticated, user } = useAuth();

  return (
    <div className="container py-5">
      <div className="text-center mb-5">
        <h1 className="display-4">Welcome to Microservices App</h1>
        <p className="lead">
          A simple application demonstrating microservices architecture with FastAPI and MySQL.
        </p>
      </div>

      <div className="row justify-content-center">
        <div className="col-md-8">
          <div className="card shadow-sm">
            <div className="card-body">
              {isAuthenticated ? (
                <>
                  <h3>Hello, {user.email}!</h3>
                  <p>You are now logged in. Explore our features:</p>
                  <div className="d-grid gap-2 col-md-6 mx-auto mt-4">
                    <Link to="/profile" className="btn btn-primary">View Profile</Link>
                  </div>
                </>
              ) : (
                <>
                  <h3>Get Started</h3>
                  <p>Please login or register to access all features.</p>
                  <div className="d-grid gap-2 col-md-6 mx-auto mt-4">
                    <Link to="/login" className="btn btn-primary mb-2">Login</Link>
                    <Link to="/register" className="btn btn-outline-primary">Register</Link>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="row mt-5">
        <div className="col-md-4">
          <div className="card mb-4">
            <div className="card-body">
              <h5 className="card-title">Authentication Service</h5>
              <p className="card-text">Secure user authentication and authorization with JWT tokens.</p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card mb-4">
            <div className="card-body">
              <h5 className="card-title">User Profiles</h5>
              <p className="card-text">Manage your user profile information securely in our database.</p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card mb-4">
            <div className="card-body">
              <h5 className="card-title">Notifications</h5>
              <p className="card-text">Email notifications to keep you updated.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Home; 