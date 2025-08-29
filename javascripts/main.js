// assets/js/main.js

// Header scroll effect
window.addEventListener('scroll', function() {
    const header = document.querySelector('.header');
    if (window.scrollY > 100) {
        header.style.background = 'rgba(255, 255, 255, 0.98)';
        header.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.1)';
    } else {
        header.style.background = 'rgba(255, 255, 255, 0.95)';
        header.style.boxShadow = 'none';
    }
});

// Animate elements when they come into view
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.animationPlayState = 'running';
        }
    });
}, observerOptions);

document.querySelectorAll('.fade-in').forEach(el => {
    el.style.animationPlayState = 'paused';
    observer.observe(el);
});

// Mobile sidebar toggle functionality (for blog pages)
const sidebarToggle = document.querySelector('.sidebar-toggle');
if (sidebarToggle) {
    sidebarToggle.addEventListener('click', function() {
        const sidebar = document.querySelector('.blog-sidebar');
        const toggle = this;

        sidebar.classList.toggle('expanded');
        toggle.classList.toggle('active');
    });
}

// Mobile menu toggle
const mobileToggle = document.querySelector('.mobile-menu-toggle');
if (mobileToggle) {
    mobileToggle.addEventListener('click', function() {
        const navLinks = document.querySelector('.nav-links');
        const toggle = this;

        navLinks.classList.toggle('mobile-open');
        toggle.classList.toggle('active');
    });
}

// Feature card interactions (homepage)
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-8px) scale(1.02)';
    });
    
    card.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0) scale(1)';
    });
});

// Docs card interactions
document.querySelectorAll('.docs-card').forEach(card => {
    card.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-4px) scale(1.01)';
    });
    
    card.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0) scale(1)';
    });
});

// Sidebar link interactions (docs pages)
document.querySelectorAll('.sidebar-links a').forEach(link => {
    link.addEventListener('click', function(e) {
        e.preventDefault();
        // Remove active class from all links
        document.querySelectorAll('.sidebar-links a').forEach(l => l.classList.remove('active'));
        // Add active class to clicked link
        this.classList.add('active');
    });
});

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Code window typing effect (homepage)
setTimeout(() => {
    const codeLines = document.querySelectorAll('.code-line');
    if (codeLines.length > 0) {
        codeLines.forEach((line, index) => {
            line.style.opacity = '0';
            setTimeout(() => {
                line.style.opacity = '1';
                line.style.transform = 'translateX(0)';
            }, index * 200);
            line.style.transform = 'translateX(-20px)';
            line.style.transition = 'all 0.3s ease';
        });
    }
}, 1000);
