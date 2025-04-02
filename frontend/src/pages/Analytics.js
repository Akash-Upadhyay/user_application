import React, { useState, useEffect } from 'react';
import { useAuth } from '../services/AuthContext';
import { analyticsService } from '../services/api';

const Analytics = () => {
  const { user } = useAuth();
  const [events, setEvents] = useState([]);
  const [summary, setSummary] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterType, setFilterType] = useState('');

  useEffect(() => {
    fetchData();
  }, [filterType]);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Get events
      const eventsResponse = await analyticsService.getEvents(filterType || null);
      setEvents(eventsResponse.data);
      
      // Get summary
      const summaryResponse = await analyticsService.getSummary();
      setSummary(summaryResponse.data);
    } catch (error) {
      console.error("Failed to load analytics data:", error);
      setError("Failed to load analytics data. Please try again later.");
    } finally {
      setLoading(false);
    }
  };

  const handleClearEvents = async () => {
    try {
      await analyticsService.clearEvents();
      fetchData();
    } catch (error) {
      console.error("Failed to clear events:", error);
      setError("Failed to clear events. Please try again later.");
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  const eventTypeColors = {
    login: 'primary',
    logout: 'secondary',
    page_view: 'info',
    profile_update: 'success',
    button_click: 'warning'
  };

  const getEventColor = (eventType) => {
    return eventTypeColors[eventType] || 'dark';
  };

  if (loading) {
    return (
      <div className="container py-5 text-center">
        <div className="spinner-border" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
        <p className="mt-3">Loading analytics data...</p>
      </div>
    );
  }

  return (
    <div className="container py-5">
      <div className="row mb-4">
        <div className="col">
          <h1 className="mb-4">Analytics Dashboard</h1>
          {error && (
            <div className="alert alert-danger" role="alert">
              {error}
            </div>
          )}
        </div>
      </div>

      {/* Summary Section */}
      <div className="row mb-4">
        <div className="col">
          <div className="card shadow">
            <div className="card-header bg-primary text-white">
              <h5 className="card-title mb-0">Event Summary</h5>
            </div>
            <div className="card-body">
              <div className="row">
                {summary.map((item) => (
                  <div className="col-md-3 mb-3" key={item.event_type}>
                    <div className={`card bg-${getEventColor(item.event_type)} text-white`}>
                      <div className="card-body">
                        <h5 className="card-title">{item.event_type}</h5>
                        <p className="card-text display-6">{item.count}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Events Section */}
      <div className="row">
        <div className="col">
          <div className="card shadow">
            <div className="card-header bg-secondary text-white d-flex justify-content-between align-items-center">
              <h5 className="card-title mb-0">Event Log</h5>
              <div>
                <select 
                  className="form-select form-select-sm me-2 d-inline-block" 
                  style={{width: "auto"}}
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value)}
                >
                  <option value="">All Events</option>
                  {summary.map(item => (
                    <option key={item.event_type} value={item.event_type}>
                      {item.event_type}
                    </option>
                  ))}
                </select>
                <button 
                  className="btn btn-sm btn-danger" 
                  onClick={handleClearEvents}
                >
                  Clear Events
                </button>
              </div>
            </div>
            <div className="card-body">
              <div className="table-responsive">
                <table className="table table-striped">
                  <thead>
                    <tr>
                      <th>Time</th>
                      <th>User ID</th>
                      <th>Event Type</th>
                      <th>Data</th>
                    </tr>
                  </thead>
                  <tbody>
                    {events.length === 0 ? (
                      <tr>
                        <td colSpan="4" className="text-center">No events found</td>
                      </tr>
                    ) : (
                      events.map((event) => (
                        <tr key={event.id}>
                          <td>{formatDate(event.timestamp)}</td>
                          <td>{event.user_id || 'Anonymous'}</td>
                          <td>
                            <span className={`badge bg-${getEventColor(event.event_type)}`}>
                              {event.event_type}
                            </span>
                          </td>
                          <td>
                            <pre className="mb-0" style={{fontSize: '0.8rem'}}>
                              {JSON.stringify(event.event_data, null, 2)}
                            </pre>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Analytics; 