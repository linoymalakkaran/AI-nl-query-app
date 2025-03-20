import React, { useState } from 'react';
import './App.css';

function App() {
  const [query, setQuery] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await fetch('http://localhost:5000/api/query', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      });
      
      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error('Error:', error);
      setResult({ error: 'Failed to process your query. Please try again.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Database Query Assistant</h1>
        <p>Ask questions about orders and inventory in plain English</p>
      </header>
      
      <main>
        <form onSubmit={handleSubmit}>
          <div className="query-input">
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Example: Show me all pending orders for customer Smith"
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Processing...' : 'Search'}
            </button>
          </div>
        </form>
        
        {result && (
          <div className="result-container">
            {result.error ? (
              <div className="error-message">{result.error}</div>
            ) : result.message ? (
              <div className="info-message">{result.message}</div>
            ) : (
              <>
                <h2>{result.question}</h2>
                <div className="result-data">
                  {result.data && result.data.length > 0 ? (
                    <table>
                      <thead>
                        <tr>
                          {Object.keys(result.data[0]).map(key => (
                            <th key={key}>{key}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {result.data.map((item, index) => (
                          <tr key={index}>
                            {Object.values(item).map((value, i) => (
                              <td key={i}>{value !== null ? value : 'N/A'}</td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  ) : (
                    <p>No data found matching your query.</p>
                  )}
                </div>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
