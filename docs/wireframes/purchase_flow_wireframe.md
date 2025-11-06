
# HobbyApp Purchase Flow Wireframe

This document outlines the user flow for purchasing credits and subscriptions within the HobbyApp.

```mermaid
graph TD
    subgraph "Main App"
        A[User wants to book a class] --> B{Has enough credits?};
        B -- Yes --> C[Book Class Flow];
        B -- No --> D[Show "Out of Credits" Modal];
        E[User navigates to Profile/Store] --> F[Store View];
    end

    subgraph "Out of Credits Modal"
        D --> D1["You need X more credits"];
        D1 --> D2{Choose an option};
        D2 -- "Buy a Pack" --> F;
        D2 -- "Subscribe & Save" --> F;
    end

    subgraph "Store View"
        F --> G[Picker: "Credit Packs" / "Subscriptions"];
        G -- "Credit Packs" --> H[Display 4 One-Time Packs];
        G -- "Subscriptions" --> I[Display 3 Subscription Tiers];
        H --> J[User taps "Purchase"];
        I --> K[User taps "Subscribe"];
    end

    subgraph "Apple Purchase Flow"
        J --> L[Apple IAP Sheet];
        K --> L;
        L --> M{Purchase Success?};
        M -- Yes --> N[App sends receipt to Supabase for validation];
        M -- No --> O[Show error message];
    end

    subgraph "Backend & Confirmation"
        N --> P[Supabase validates receipt];
        P --> Q{Validation Success?};
        Q -- Yes --> R[Supabase adds credits to user's account];
        Q -- No --> S[Handle validation error];
        R --> T[App UI updates with new credit balance];
        T --> A;
    end

    C --> U[End];
    O --> F;
    S --> F;
```

## Flow Description

1.  **Trigger Point:** The purchase flow can be triggered in two main ways:
    *   **Proactively:** The user navigates to the store from their profile or another CTA.
    *   **Reactively:** The user attempts to book a class but lacks the required credits.

2.  **"Out of Credits" Scenario:** If a user doesn't have enough credits, a modal view appears, clearly stating the deficit and prompting them to either buy a one-time pack or subscribe for better value. Both options lead to the main `StoreView`.

3.  **Store View:** This is the central hub for all purchases.
    *   A picker allows users to toggle between viewing one-time **Credit Packs** and recurring **Subscriptions**.
    *   Each option is displayed in a clear, card-based UI with its name, cost, credits, and a brief description.
    *   Tapping "Purchase" or "Subscribe" initiates the standard Apple In-App Purchase flow.

4.  **Backend Validation:** Upon a successful Apple IAP transaction, the app does **not** immediately grant the credits. Instead, it sends the encrypted transaction receipt to a secure Supabase Edge Function. The backend validates this receipt with Apple's servers.

5.  **Confirmation:** Only after successful server-side validation does Supabase update the user's credit balance in the database. The app then refreshes the UI to show the new balance, and the user can proceed with their booking. This secure flow prevents fraudulent purchases.
