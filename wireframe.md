# Garuda App Wireframe

Copy and paste the following Mermaid code into [Mermaid Live Editor](https://mermaid.live/) or any Markdown viewer that supports Mermaid (like GitHub) to see the visual flow of the application screens.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"primaryColor": "#1E293B", "primaryTextColor": "#F8FAFC", "primaryBorderColor": "#334155", "lineColor": "#475569"}}}%%
flowchart TD
    classDef default fill:#1E293B,stroke:#334155,stroke-width:1px,color:#F8FAFC;
    classDef auth fill:#0F172A,stroke:#A855F7,stroke-width:2px,color:#F8FAFC;
    classDef supplier fill:#0F172A,stroke:#10B981,stroke-width:2px,color:#F8FAFC;
    classDef logistics fill:#0F172A,stroke:#F43F5E,stroke-width:2px,color:#F8FAFC;
    classDef driver fill:#0F172A,stroke:#F59E0B,stroke-width:2px,color:#F8FAFC;
    classDef consumer fill:#0F172A,stroke:#38BDF8,stroke-width:2px,color:#F8FAFC;
    classDef overlay fill:#000000,stroke:#F59E0B,stroke-width:2px,stroke-dasharray: 5 5,color:#F8FAFC;

    %% Authentication Flow
    Login([Login / Auth Screen]):::auth
    RoleSelection{Select User Role}:::auth
    
    Login --> RoleSelection

    %% Supplier Flow
    RoleSelection -->|Supplier| SuppHome[Supplier Home Dashboard]:::supplier
    SuppHome --> SuppCreate[Create Shipment Screen]:::supplier
    SuppCreate --> SuppMap[Location Picker Map]:::supplier
    SuppCreate --> SuppPreflight[AI Pre-flight Risk Analysis]:::supplier
    SuppHome --> SuppDetails[Shipment Details & Cost Analytics]:::supplier

    %% Logistics Admin Flow
    RoleSelection -->|Logistics Admin| LogHome[Logistics Dashboard]:::logistics
    LogHome --> LogAssign[Assign Driver / Fleet Screen]:::logistics
    LogHome --> LogLive[Live Fleet Heatmap]:::logistics

    %% Driver Flow
    RoleSelection -->|Driver| DrvHome[Driver Assigned Rides]:::driver
    DrvHome --> DrvActive[Active Ride Screen]:::driver
    DrvActive --> DrvNav[Google Maps Intent Navigation]:::driver
    DrvNav -.-> DrvOverlay((Garuda AI Floating Bubble)):::overlay
    DrvOverlay -.->|Tap to Expand| DrvAlertPanel[AI Risk Alert Panel]:::overlay
    DrvAlertPanel -.->|Accept Reroute| DrvNav

    %% Consumer Flow
    RoleSelection -->|Consumer| ConHome[Consumer Tracking Portal]:::consumer
    ConHome --> ConTrack[Enter Tracking ID]:::consumer
    ConTrack --> ConLive[Live Interactive Map]:::consumer
    ConLive --> ConExplain[Gemini AI Delay Explanation]:::consumer

    %% Styling linkages
    linkStyle default stroke:#475569,stroke-width:2px;
```
