import React from 'react';

const Footer = () => {
  return (
    <footer className="bg-light py-4 text-center">
      <div className="container">
        <p className="text-muted mb-0">
          &copy; {new Date().getFullYear()} Microservices Application Demo
        </p>
      </div>
    </footer>
  );
};

export default Footer; 