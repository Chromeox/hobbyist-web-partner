'use client';

import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Database, RefreshCw, AlertCircle } from 'lucide-react';

interface Props {
  children: ReactNode;
  dataType?: string;
  onRetry?: () => void;
}

interface State {
  hasError: boolean;
  error?: Error;
}

class DataErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error(`Data Error (${this.props.dataType}):`, error);
    console.error('Error Info:', errorInfo);
  }

  handleRetry = () => {
    this.setState({ hasError: false });
    if (this.props.onRetry) {
      this.props.onRetry();
    }
  };

  render() {
    if (this.state.hasError) {
      const dataType = this.props.dataType || 'data';
      
      return (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <div className="rounded-full bg-red-100 p-2 mt-1">
              <AlertCircle className="h-4 w-4 text-red-600" />
            </div>
            
            <div className="flex-1">
              <h4 className="text-sm font-medium text-red-900 mb-1">
                Unable to load {dataType}
              </h4>
              
              <p className="text-sm text-red-700 mb-3">
                There was a problem fetching the {dataType}. Please check your connection and try again.
              </p>

              {process.env.NODE_ENV === 'development' && this.state.error && (
                <div className="bg-red-100 rounded p-2 mb-3">
                  <details className="text-xs">
                    <summary className="font-medium text-red-800 cursor-pointer">
                      Error Details
                    </summary>
                    <pre className="mt-1 text-red-700 overflow-auto max-h-20">
                      {this.state.error.message}
                    </pre>
                  </details>
                </div>
              )}
              
              <button
                onClick={this.handleRetry}
                className="inline-flex items-center gap-2 px-3 py-1.5 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                <RefreshCw className="h-3 w-3" />
                Retry
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default DataErrorBoundary;