# Hobby Directory - Webflow + React Components

Vancouver's premier creative event discovery platform built with React components integrated into Webflow via DevLink.

## 🎯 Project Overview

This project provides React components that fetch data directly from Airtable and can be imported into Webflow using DevLink. This approach combines the best of both worlds:
- **Webflow**: Visual design tools, hosting, and CMS
- **React**: Custom data logic, real-time API integration, and advanced filtering
- **Airtable**: Flexible database with approval workflow

## 🏗️ Architecture

```
Instagram Scraper (6am/6pm)
  ↓
Airtable (pending events)
  ↓
7:30am Review in Airtable Interface
  ↓
Approve (mark as active)
  ↓
React Components (fetch from Airtable API)
  ↓
Webflow Site (visual design + hosting)
  ↓
Live Directory (hobby.directory)
```

## 📦 Tech Stack

- **React 19** with TypeScript
- **Airtable** as the database
- **SWR** for data fetching and caching
- **date-fns** for date manipulation
- **Webflow DevLink** for integration

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ installed
- Airtable account with API key
- Webflow account (free trial available)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Configure environment variables:
```bash
cp .env.local .env
# Edit .env and add your Airtable credentials
```

3. Install Webflow CLI (already installed globally):
```bash
# Already installed: @webflow/webflow-cli
```

### Development Workflow

1. **Build React components** (already created):
   - EventCard
   - EventGrid
   - EventDetail
   - Custom hooks with SWR caching

2. **Initialize DevLink**:
```bash
npm run devlink:init
```
This will prompt you to authenticate with Webflow and select your site.

3. **Sync components to Webflow**:
```bash
npm run devlink:sync
```
This exports your React components so they can be imported into Webflow Designer.

4. **Design in Webflow**:
   - Open your Webflow project
   - Add your React components to pages
   - Style with Webflow's visual designer
   - Configure responsive breakpoints

5. **Publish**:
   - Publish from Webflow Dashboard
   - Components will fetch real-time data from Airtable

## 📁 Project Structure

```
hobby-directory-webflow/
├── src/
│   ├── components/
│   │   ├── EventCard.tsx       # Card display for events
│   │   ├── EventGrid.tsx       # Grid layout with filtering
│   │   ├── EventDetail.tsx     # Full event detail page
│   │   └── FilterSidebar.tsx   # (TODO) Filter controls
│   ├── hooks/
│   │   └── useEvents.ts        # SWR hooks for data fetching
│   ├── lib/
│   │   └── airtable.ts         # Airtable API client
│   └── types/
│       └── index.ts            # TypeScript interfaces
├── .env.local                   # Environment variables
├── package.json
├── tsconfig.json
└── README.md
```

## 🔧 Configuration

### Environment Variables

Create a `.env.local` file:

```env
AIRTABLE_API_KEY=your_api_key_here
AIRTABLE_BASE_ID=your_base_id_here
```

**Note**: Your Airtable API key is already configured in `.env.local`.

### Airtable Base

Your Airtable base should have the following tables:
- **Events**: Event listings
- **Studios**: Studio/creator information
- **ContentQueue**: Review workflow
- **Analytics**: Performance metrics

See `../hobbybot/airtable_schema.json` for the complete schema.

## 📋 Components

### EventCard

Displays event information in a card format.

**Props**:
- `event: EventCardData` - Event data object
- `variant?: 'compact' | 'standard' | 'featured'` - Card style
- `showStudio?: boolean` - Show/hide studio name
- `onClick?: (event) => void` - Click handler

### EventGrid

Grid layout for displaying multiple events with filtering.

**Props**:
- `initialFilters?: FilterState` - Initial filter values
- `layout?: 'grid' | 'list'` - Display layout
- `showFilters?: boolean` - Show filter controls
- `maxItems?: number` - Limit displayed items

### EventDetail

Full event detail page with booking sidebar and related events.

**Props**:
- `slug: string` - Event slug for fetching

## 🎨 Styling

Components use semantic CSS classes that can be styled in Webflow:
- `.event-card` - Event card container
- `.event-card__image` - Event image
- `.event-card__title` - Event title
- `.event-card__badge` - Urgency badges (TODAY, FINAL SPOTS, etc.)
- `.event-grid` - Event grid container
- `.event-detail` - Event detail page container
- `.booking-sidebar` - Booking sidebar

## 🔄 Data Flow

1. **Airtable → React**: Components fetch data via Airtable API
2. **SWR Caching**: Responses cached for 5 minutes
3. **Real-time Updates**: No sync delay (unlike WhaleSync)
4. **Filtering**: Client-side filtering for instant results

## 📊 Performance

- **Caching**: 5-10 minute cache on API responses
- **Lazy Loading**: Images load on scroll
- **Debouncing**: Search queries debounced by 300ms
- **Pagination**: Optional maxItems prop to limit data

## 🚧 TODO

- [ ] FilterSidebar component
- [ ] Search bar component
- [ ] Map view component
- [ ] Newsletter signup component
- [ ] Studio directory page
- [ ] Analytics tracking integration

## 📚 Documentation

- [Complete Design Spec](../HOBBY_DIRECTORY_DESIGN_SPEC.md)
- [Airtable Schema](../hobbybot/airtable_schema.json)
- [Webflow DevLink Docs](https://developers.webflow.com)

## 🐛 Troubleshooting

### "Airtable credentials not configured"
Make sure `.env.local` has `AIRTABLE_API_KEY` and `AIRTABLE_BASE_ID` set.

### DevLink not syncing
Run `webflow devlink sync` and ensure you're authenticated.

### Components not appearing in Webflow
Check that your components are exported and the DevLink sync completed successfully.

## 📝 License

ISC
