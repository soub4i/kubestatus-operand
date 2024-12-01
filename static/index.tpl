<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubestatus UI</title>
    <script src="https://unpkg.com/preact@10.11.3/dist/preact.min.js"></script>
    <script src="https://unpkg.com/preact@10.11.3/hooks/dist/hooks.umd.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {},
            },
        }
    </script>
    <style>
        @media (prefers-color-scheme: dark) {
            :root {
                color-scheme: dark;
            }
        }
    </style>
</head>
<body>
    <div id="app"></div>
    <script type="module">
        const { h, render } = preact;
        const { useState, useEffect } = preactHooks;

        const StatusIcon = ({ status }) => {
            const icons = {
                operational: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-6 h-6 text-green-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
                degraded: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-6 h-6 text-yellow-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>',
                down: '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-6 h-6 text-red-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
            };
            return h('span', { dangerouslySetInnerHTML: { __html: icons[status] } });
        };

        const PublicIcon = ({ isPublic }) => {
            const icon = isPublic === "true"
                ? '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-6 h-6 text-blue-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
                : '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" class="w-6 h-6 text-gray-500"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>';
            return h('span', { 
                dangerouslySetInnerHTML: { __html: icon },
                "aria-label": isPublic === "true" ? "Public service" : "Private service"
            });
        };

        const App = () => {
            const [isDarkMode, setIsDarkMode] = useState(false);
            const [services, setServices] = useState([]);
            const [lastRefresh, setLastRefresh] = useState(new Date());
            const [error, setError] = useState(null);
            const [isLoading, setIsLoading] = useState(true);
            const [activeRefreshInterval, setActiveRefreshInterval] = useState(null);

            useEffect(() => {
                const root = window.document.documentElement;
                if (isDarkMode) {
                    root.classList.add('dark');
                } else {
                    root.classList.remove('dark');
                }
            }, [isDarkMode]);
            const u = "{{.Username}}";
            const p = "{{.Password}}";
            const fetchServices = async () => {
                setIsLoading(true);
                setError(null);
                try {
                    const headers = new Headers();
                    headers.set('Authorization', 'Basic ' + btoa( u  + ":" + p));
                    const response = await fetch('/status', { mode: 'cors', headers: headers, method :'GET' });
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    const data = await response.json();
                    setServices(data);
                    setLastRefresh(new Date());
                } catch (e) {
                    setError('Failed to fetch services. Please try again later.');
                    console.error('Error fetching services:', e);
                } finally {
                    setIsLoading(false);
                }
            };

            useEffect(() => {
                fetchServices();
                const interval = setInterval(fetchServices, 30000);
                setActiveRefreshInterval(interval);
                return () => {
                    if (activeRefreshInterval) {
                        clearInterval(activeRefreshInterval);
                    }
                };
            }, []);

        const GlobalStatus = ({ status }) => {
          const statusColors = {
            operational: 'bg-green-500',
            degraded: 'bg-yellow-500',
            down: 'bg-red-500',
            unknown: 'bg-gray-500'
          };
          return h('div', { className: 'mb-6 p-4 rounded-lg bg-white dark:bg-gray-800 shadow' }, [
            h('h2', { className: 'text-xl font-semibold mb-2 text-gray-900 dark:text-white' }, 'Cluster Status'),
            h('div', { className: 'flex items-center' }, [
              h('div', { className: `w-4 h-4 rounded-full ${statusColors[status]} mr-2` }),
              h('span', { className: 'text-lg font-medium text-gray-700 dark:text-gray-300 capitalize' }, status)
            ])
          ]);
        };
        const calculateGlobalStatus = (services) => {
        if (services.length === 0) return 'unknown';
          if (services.every(s => s.status === 'operational')) return 'operational';
          if (services.every(s => s.status === 'down')) return 'down';
          if (services.some(s => s.status === 'down')) return 'degraded';
          return 'degraded';
        };

            return h('div', { className: `min-h-screen flex flex-col ${isDarkMode ? 'dark' : ''}` }, [
                h('header', { className: "bg-white dark:bg-gray-800 shadow" },
                    h('div', { className: "max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8" },
                        h('div', { className: "flex justify-between items-center" }, [
                            h('div', null, [
                                h('h1', { className: "text-3xl font-bold text-gray-900 dark:text-white" }, "Kubestatus UI"),
                                h('p', { className: "mt-1 text-sm text-gray-600 dark:text-gray-400" }, "Keeping you informed, every step of the way | Kubestatus")
                            ]),
                            h('button', {
                                onClick: () => setIsDarkMode(!isDarkMode),
                                className: "p-2 rounded-full bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200",
                                "aria-label": isDarkMode ? "Switch to light mode" : "Switch to dark mode"
                            }, 
                                h('span', { dangerouslySetInnerHTML: { __html: isDarkMode
                                    ? '<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" /></svg>'
                                    : '<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" /></svg>'
                                } })
                            )
                        ])
                    )
                ),
                h('main', { className: "flex-grow bg-gray-100 dark:bg-gray-900" },
                    h('div', { className: "max-w-7xl mx-auto py-6 sm:px-6 lg:px-8" },
                        h('div', { className: "px-4 py-6 sm:px-0" },
                            h('div', { className: "border-4 border-dashed border-gray-200 dark:border-gray-700 rounded-lg p-4" }, [
                                h('div', { className: "flex justify-between items-center mb-4" }, [
                                    h('div', { className: "text-sm text-gray-500 dark:text-gray-400" },
                                        `Last refreshed: ${lastRefresh.toLocaleTimeString()}`
                                    ),
                                    h('div', { className: "flex space-x-2" },
                                        [
                                            { label: '10s', duration: 10000 },
                                            { label: '30s', duration: 30000 },
                                            { label: '1m', duration: 60000 },
                                        ].map(({ label, duration }) =>
                                            h('button', {
                                                key: label,
                                                onClick: () => {
                                                    if (activeRefreshInterval) {
                                                        clearInterval(activeRefreshInterval);
                                                    }
                                                    fetchServices();
                                                    const interval = setInterval(fetchServices, duration);
                                                    setActiveRefreshInterval(interval);
                                                },
                                                className: `px-2 py-1 rounded-full font-semibold text-sm transition-colors duration-150 ease-in-out focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
                                                    activeRefreshInterval && duration === activeRefreshInterval._repeat
                                                        ? 'bg-blue-600 text-white hover:bg-blue-700'
                                                        : 'bg-blue-100 text-blue-700 hover:bg-blue-200'
                                                }`
                                            }, [
                                                label,
                                                activeRefreshInterval && duration === activeRefreshInterval._repeat &&
                                                    h('span', { className: 'ml-2 inline-block w-2 h-2 bg-white rounded-full' })
                                            ])
                                        )
                                    )
                                ]),
                                
                                h(GlobalStatus, { status: calculateGlobalStatus(services) }),
                                isLoading ? h('p', { className: "text-center text-gray-500 dark:text-gray-400" }, "Loading services...") :
                                error ? h('p', { className: "text-center text-red-500" }, error) :
                                h('ul', { className: "divide-y divide-gray-200 dark:divide-gray-700" },
                                services && services.length > 0 ? services.map((service) =>
                                        h('li', { key: service.name, className: "py-4" },
                                            h('div', { className: "flex items-center justify-between" }, [
                                                h('div', { className: "flex items-center" }, [
                                                    h('div', { className: "flex-shrink-0" },
                                                        h(PublicIcon, { isPublic: service.is_public })
                                                    ),
                                                    h('div', { className: "ml-4" },
                                                        h('h2', { className: "text-lg font-medium text-gray-900 dark:text-white" }, service.name)
                                                    )
                                                ]),
                                                h('div', { className: "flex items-center" }, [
                                                    h(StatusIcon, { status: service.status }),
                                                    h('span', { className: "ml-2 text-sm font-medium text-gray-500 dark:text-gray-400 capitalize" },
                                                        service.status
                                                    )
                                                ])
                                            ])
                                        )
                                    ) : h('h4', { className: "text-sm text-gray-900 dark:text-white text-center" }, "No Services. Make sure you annotate the services so Kubestaus can watch it") 
                                )
                            ])
                        )
                    )
                ),
                h('footer', { className: "bg-white dark:bg-gray-800 shadow" },
                    h('div', { className: "max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8" },
                        h('p', { className: "text-center text-sm text-gray-500 dark:text-gray-400" },
                            `© ${new Date().getFullYear()}. All rights reserved.`
                        )
                    )
                )
            ]);
        };

        render(h(App), document.getElementById('app'));
    </script>
</body>
</html>