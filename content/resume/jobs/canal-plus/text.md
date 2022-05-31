## About the Canal Plus and the Mediahub project

Canal Plus is a glboal leader of pay-television, movie production and movie distribution. 

My team is building Mediahub, a media asset management system (MAM), the cornerstone
of the video supply chain. This platform is replacing several separated legacy tools and addressing some of the group's
biggest challenges: delivering UHD content at scale, operating hundreds of TV channels worldwide as Canal+ expands and keeping track
of versions, languages and rights associated with each asset ; allowing archivists to index and retrieve more content every day.

We are storing decades worth of movies and TV shows, and ingesting 300+ hours of new content on a daily basis.
The platform is responsible for transcoding assets as they enter and leave the system, creating proxies out of high quality masters, storing
and retrieving assets from hot and cold storage and more. 

## Work environment

## My contribution

- As a lead Scala developer, I used **Kafka and fs2** to develop ETLs that allowed us move massive amounts of data safely from the legacy systems, and
  eventually shut down legacy systems. 
- I'm leading the archiving feature team. My team is providing archivists the tools they need to document and retrieve videos from a very large catalog.
  We're building the archiving features using **Kafka, fs2, Postgres and Elasticsearch**.
- I trained some of my coworkers to **Cats and Cats Effect**, and I'm encouraging a purely functional style. 
- I've also introduced hexagonal architecture and property-based testing using **Scalacheck**. 
  
  I find the combination of purely functional programming, thoughtful error management, clear separation of the domain and application layers through
  hexagonal architecture, and fearless concurrency has allowed us to build great software.
- I introduced Tapir in the project to streamline the way we document our 100+ micro services and the way they talk to each other. 
  HTTP clients are now automatically derived from a statically-typed endpoint definition.
- I'm also striving to continuously improve our large code base (over 100+ microservices) and keeping a close eye on technical debt: 
  I'm keeping a continuous improvement backlog and I'm organizing continuous improvement workshops.
- I've led several technical interviews as part of our recruiting process, and I take part in the evaluation of our consultants
- I've spoken twice at the company-wide development conference
- I've co-organized several *brown-bag sessions* where we discussed testing, software architecture and libraries
