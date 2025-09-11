{\rtf1\ansi\ansicpg1252\cocoartf2862
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fmodern\fcharset0 Courier;}
{\colortbl;\red255\green255\blue255;\red16\green16\blue16;\red255\green255\blue255;}
{\*\expandedcolortbl;;\cssrgb\c7451\c7451\c7843;\cssrgb\c100000\c100000\c100000;}
\margl1440\margr1440\vieww12720\viewh7000\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs28 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 # Building and Monetising a Local Directory Website\
\
This document summarises how to build a local directory website using no-code tools and outlines various strategies for monetising it, including a detailed look at implementing search and filtering with Finsweet CMS Filter.\
\
## Part 1: Building a Local Directory Website\
\
Building a local directory website, such as "the running directory" (which lists running races and run clubs in Canada), can be achieved efficiently using no-code tools [1, 2]. The entire site can be set up in approximately **48 hours**, requiring about two 8-hour shifts (16 hours) for the Minimum Viable Product (MVP), including design and backend functionality [1, 3].\
\
### 1. Website Creation\
\
The primary tool for creating the website is **Webflow** [4].\
\
*   **Static Pages:** The initial iteration of a directory site can be kept simple with a few static pages: a homepage, a listings page for races with search and filtering, a similar page for run clubs, and a contact page [4].\
*   **Contact Page:** The contact page can include links or forms allowing visitors to suggest new run clubs or races, which then populate the database [5].\
*   **Webflow CMS (Content Management System):** This internal Webflow tool is crucial for directory sites. It allows for the creation of **CMS collections**, which act as an internal database to store information for templated pages (e.g., race or run club profiles) and listing cards [5, 6].\
    *   **CMS Collection Fields:** For "the running directory," CMS collections include fields such as race title, location, image, event date, and various labels [6, 7].\
    *   **Template Pages:** When a CMS collection is created, Webflow also generates a template page. While more detailed profile pages can be built, in the first iteration, clicking on a listing card can directly redirect users to an external registration page [8].\
*   **Relume Components:** To accelerate the Webflow development process, **Relume Components** can be used. This component library, integrated as an app within Webflow, allows users to quickly import pre-designed elements, including styles, and then make necessary adjustments [4, 9, 10]. It significantly saves time, especially for mobile responsiveness [11].\
\
### 2. Database Management\
\
While Webflow CMS stores information, **Airtable** is used as the primary database for managing and enriching data [11].\
\
*   **Airtable Tables:** Key tables for a directory might include races, run clubs, cities, provinces, and mailing list sign-ups [12]. These tables are directly linked to the Webflow CMS [12].\
*   **Field Correspondence:** It is recommended to first build out all CMS collections in Webflow, defining the necessary fields for preview cards or detail pages. Then, corresponding fields should be created in Airtable [13].\
    *   Airtable offers advanced functionalities, such as **formula fields**, which can calculate dynamic labels (e.g., "10 days to go" for a race date) that can then be sent back to Webflow [14, 15].\
\
### 3. Data Syncing\
\
To ensure data consistency between Airtable and Webflow, a syncing tool is essential.\
\
*   **Whalesync:** This tool enables **bidirectional syncing** between Airtable and Webflow [16, 17].\
    *   **Setup:** Users create an account, connect their Airtable base and Webflow site, and then import and map corresponding tables and fields [16, 18, 19]. For example, an "image" field in Airtable can be mapped to a "logo" field in Webflow CMS [19].\
    *   **Bidirectional Sync:** Changes made in either Airtable or Webflow are automatically synced to the other platform, keeping information consistent [17].\
    *   **Simplicity:** Whalesync is noted for being simpler to set up compared to other automation tools like make.com [20].\
    *   **Automatic Field Detection:** If Webflow CMS collection fields share the exact same names as Airtable fields, Whalesync can automatically detect and map them, simplifying the process [20].\
    *   **Filters:** Whalesync's filter feature allows users to control which records sync. For example, data can be set to sync only when a record's status is "active" [21]. These filters must be set up **initially** before the syncing process begins, as they cannot be changed afterwards [22].\
    *   **Auto-Create Tables (New Feature):** A new feature allows users to set up collections in Webflow CMS, and then Whalesync can automatically generate corresponding tables and fields in Airtable, establishing the sync [23-25].\
\
### 4. Populating the Database\
\
Finding and populating the database with high-quality information is a crucial step [25].\
\
*   **Initial Data Source:** Depending on the directory, there might be an existing "seed database" [25].\
*   **Web Clippers:** For specific data types (e.g., run clubs on Instagram), a custom web clipper can be created to automate data import into Airtable [26].\
    *   The web clipper can import details such as the run club's name, link, profile picture, and description [26, 27].\
    *   Advanced techniques using **CSS selectors** can target specific text content on a page to pull in information automatically [28-30].\
*   **Data Enrichment:** Workflows can be set up within Airtable to read descriptions and extract specific values (e.g., meeting day, time, location) for use in search and filtering [27, 28].\
\
### 5. Search and Filtering\
\
Implementing robust search and filtering functionality enhances the user experience on a directory site [30].\
\
*   **Finsweet CMS Filter:** This tool provides advanced no-code filtering systems for Webflow CMS Collection Lists and static lists [30, 31].\
    *   **Script Installation:** The first step is to install a universal Attributes script into the `<head>` tag of your Webflow project [32, 33].\
    *   **Tagging Elements:** Elements within the collection cards and the filter UI must be tagged with specific attributes to enable search functionality [32, 34].\
        *   The **CMS Collection List** itself needs the attribute `fs-list-element="list"` [34-36].\
        *   The **Form element** containing all filter UI elements (checkboxes, radio buttons, text inputs) needs `fs-list-element="filters"` [34, 37].\
        *   **Field Identifier:** For individual filters and corresponding collection item fields, `fs-list-field="IDENTIFIER"` is used, with `IDENTIFIER` being a custom, descriptive value [38-40]. This links the filter UI to the data in the CMS [39]. The element with the matching identifier inside the Collection Item does not need to be visible; it can be hidden using `display:none` [41].\
        *   **Checkbox/Radio Value:** For checkboxes and radio buttons, `fs-list-value="VALUE"` defines their dynamic or static values [42, 43].\
    *   **Functionality:** Once elements are tagged, when a user selects a filter (e.g., "five kilometres"), the system identifies matching cards and filters out non-matching elements [38, 44]. This can be applied to various criteria like distance, day of the week, or tags [44].\
    *   **Search Field:** A `Text Input` element can be used for text-based filtering by adding `fs-list-field="IDENTIFIER"` to it. It can search one or multiple fields (e.g., `fs-list-field="title, description, category"`) or all CMS fields (`fs-list-field="*"`) [45-48].\
    *   **Clear Filters:** A button or link with `fs-list-element="clear"` can reset all active filters [49]. Specific filters can also be cleared using `fs-list-field="IDENTIFIER"` [50-52].\
    *   **Results Count:** Attributes like `fs-list-element="items-count"` display the total number of items, while `fs-list-element="results-count"` shows the current number of filtered items [53-55].\
    *   **Active Filter Tags:** An active filter tag template can be created using `fs-list-element="tag"` on a Div Block. Nested elements within this tag (e.g., `tag-field`, `tag-value`, `tag-operator`, `tag-remove`) display the filter's name, value, operator, and a remove button [53, 56-58].\
    *   **Advanced Settings:** Finsweet CMS Filter offers various optional settings like `fs-list-highlight="true"` for highlighting search terms, `fs-list-debounce="TIME_IN_MS"` to pause filter updates while typing, `fs-list-fieldtype="number"` or `date` for numerical/date comparisons, `fs-list-allowsubmit="true"` to enable form submissions, `fs-list-fuzzy="THRESHOLD"` for forgiving search, and `fs-list-filteron="VALUE"` to control when filters are applied (e.g., `change`, `submit`, or default `input`) [50, 59-66].\
    *   **Dynamic Filtered List:** This advanced setup allows users to build a custom filter UI with conditional groups and matching logic directly on the site, using a template structure defined by specific attributes [31, 67, 68].\
\
### 6. Costs\
\
Running a no-code directory site typically costs **around \'a3100 a month**. This covers expenses like the Webflow CMS plan for hosting, Whalesync, and Airtable (approximately \'a320 a month) [69, 70]. Miscellaneous costs like domain purchases are additional [70].\
\
## Part 2: Monetising a Directory Website\
\
Monetising a directory website, especially a new one with zero traffic, requires strategic approaches. While traditional models are effective with an established audience, specific strategies can generate revenue from day one [71, 72].\
\
### 1. Traditional Monetisation Models\
\
Four popular and tested models exist, but typically require an established directory and traffic to be effective [72, 73].\
\
*   **a. Ads:**\
    *   **Mechanism:** Placing banners (e.g., via Google AdSense) on the website [74, 75]. Revenue is often based on **CPM (cost per thousand impressions)**, with an average of around $2.80 per thousand impressions [75, 76].\
    *   **Effectiveness:** Requires significant page views; higher CPMs are found in niches like finance or B2B [76, 77]. The speaker does not prefer Google AdSense due to its passive nature [77].\
    *   **Alternative:** Directly reaching out to businesses in the niche to sell ad placements or sponsorships can be more profitable and flexible (e.g., monthly subscriptions) [78].\
*   **b. Affiliate Marketing:**\
    *   **Mechanism:** Earning commissions when users click on links to products or services listed on the directory and subsequently make a purchase or upgrade [79, 80]. The directory gets a cut of the revenue [80].\
    *   **Effectiveness:** Works best when the site is established, well-known, and trusted, attracting high traffic and encouraging conversions [81, 82]. A new directory will likely struggle with conversions due to lack of trust and traffic [81].\
    *   **Example:** Earning 50% of the first year's subscription for a Webflow paid plan referred through an affiliate link [83].\
*   **c. Listing Fees / Premium Listings:**\
    *   **Mechanism:** Charging businesses for inclusion in the directory or for premium features (e.g., enhanced visibility, more details) [82, 84]. This can involve a one-off fee or an upgrade from a free listing [84].\
    *   **Effectiveness:** Quality of the site and its value proposition are critical [84, 85]. A **freemium model** is recommended for new directories to build up the number of listings, with paid upgrades becoming more viable as credibility grows [85-87]. Reputation and consistent value delivery are essential for converting free sign-ups to paid customers [88, 89]. Attracting **high-intent traffic** (e.g., through good SEO or Google search ads) is also key [88, 90].\
*   **d. Lead Generation Fees:**\
    *   **Mechanism:** Charging businesses for high-quality leads generated through the directory [89, 91]. Payment is for **results**, not just exposure [92].\
    *   **Effectiveness:** Highly profitable because the directory is directly delivering value [92]. Pricing can be based on the value of a qualified lead and the average lead-to-sale conversion rate for the client, ensuring the client always makes money [93].\
    *   **Challenges:** Requires finding niches where lead generation is difficult for sellers [94]. The **quality of leads** must be consistently high to maintain business relationships and reputation [95, 96].\
\
### 2. The Directory Flywheel and Kickstarting Traffic\
\
The core challenge for new directories is getting the "flywheel" moving: generating impressions, which lead to traffic, then sign-ups/conversions, and finally sales [73, 97, 98]. Many directories fail because they struggle to kickstart this process [99].\
\
*   **Ineffective Initial Strategies:**\
    *   **SEO (Search Engine Optimisation):** While effective long-term, it requires technical expertise and takes significant time to generate meaningful traffic, which new businesses often don't have [100, 101].\
    *   **Content Marketing:** Difficult to yield results without an existing audience. Building a social media following from scratch is a slow process [101, 102].\
\
*   **The "Cheat Code": Paid Ads**\
    *   **Solution:** Paid ads (e.g., Facebook Ads, Google Ads) are recommended as a "cheat code" to generate instant impressions and traffic [103].\
    *   **Benefits:**\
        *   **Instant Results:** Delivers traffic immediately, regardless of track record [103].\
        *   **Precise Targeting:** Allows targeting specific demographics, interests, and search intents (e.g., Facebook for interests, Google for search queries) [104].\
        *   **Scalable and Predictable:** Once an effective ad campaign is found, more money can be spent to increase impressions and results [105].\
    *   **Approach for New Directories:**\
        1.  Target people in your niche with ads [106].\
        2.  Instead of direct sales, capture leads with **lead magnets**, free resources, or free sign-ups [106].\
        3.  Re-engage captured leads via email [106].\
        4.  Always offer a paid upgrade option to convert initial engagement into revenue [107].\
        5.  **Reinvest revenue from initial sales directly back into ads** to drive more traffic and accelerate the flywheel [107, 108].\
\
*   **Understanding Ad Metrics (Example Funnel):**\
    1.  **CPM (Cost Per Mille/Thousand Impressions):** How much the ad platform charges for every 1,000 impressions [108, 109].\
    2.  **Click-Through Rate (CTR):** Percentage of people who click on the ad after seeing it (e.g., 2-5% initially, improving with experimentation) [109, 110].\
    3.  **Conversions to Sign-ups:** How many website visitors convert into free accounts or sign-ups (e.g., 30 out of 1,000 clicks result in 30 free accounts) [111].\
    4.  **Conversions to Paid Accounts:** How many free accounts upgrade to paid listings (e.g., 1-2 premium listings from 30 sign-ups) [112].\
    5.  **Revenue Prediction:** By tracking these metrics, you can predict revenue based on ad spend and identify areas for optimisation (e.g., improve ads for low CTR, optimise website for low sign-up rates) [113-115].\
\
*   **Ad Channels:**\
    *   **Facebook & Instagram Ads:** Good for targeting low-intent audiences by interests, age, and location, allowing for experimentation with creative and messaging [115, 116].\
    *   **Google Search Ads:** Effective for high-intent traffic (people actively searching for something), though typically more expensive [116, 117].\
    *   **LinkedIn Ads:** Suitable if the target audience is primarily on LinkedIn, generally more expensive but with a higher value audience [117].\
    *   **Google Display Ads:** Used for retargeting people who have previously engaged with the site [118].\
\
### 3. Funding Ads with High-Value Services (When Budget is Limited)\
\
If there is no budget for paid ads, a "cash generation" strategy is recommended [119, 120].\
\
*   **Consulting Model:** Focus on selling **higher-value services** to businesses in your niche to quickly generate cash [121, 122].\
    *   **Identify Pain Points:** Research and talk to potential customers in your niche to understand their biggest operational pain points (e.g., inconsistent social content, lead follow-up issues) [121, 123].\
    *   **Create a Simple Offer:** Develop a high-value service addressing a specific pain point (e.g., "I will create all your social media content for the next three months," including deliverables and a fixed price of \'a3500-\'a32000 per project) [123-125].\
    *   **Leverage the Directory:**\
        1.  Create a **free, awesome listing** for the target business on your directory [126].\
        2.  Use this as an opening to reach out, offering to help with their pain point (e.g., social media marketing) [126, 127].\
        3.  Schedule a strategy call to add value and then pitch your service [127, 128].\
    *   **Benefits:** This model requires fewer sales to generate significant revenue, allows for outsourcing of work, builds trust and authority within the niche, and can become a major, long-term revenue stream [120, 122, 129].\
    *   **Goal:** Use this revenue to fund your ad campaigns and kickstart the directory flywheel [120, 130]. Once enough funds are generated for the directory to run itself, you can choose to continue or phase out the service work [131].\
}