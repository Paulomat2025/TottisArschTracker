using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using ArtTimeTracker.Core.Data;
using ArtTimeTracker.Core.Models;

namespace ArtTimeTracker.Core.Services;

public class DataService
{
    public DataService()
    {
        using var db = new AppDbContext();
        db.Database.EnsureCreated();
    }

    public async Task<List<Artwork>> GetArtworksAsync(bool includeArchived = false)
    {
        using var db = new AppDbContext();
        var query = db.Artworks.Include(a => a.Sessions).AsQueryable();
        if (!includeArchived)
            query = query.Where(a => !a.IsArchived);
        return await query.OrderByDescending(a => a.CreatedAt).ToListAsync();
    }

    /// <summary>Sucht ein Kunstwerk anhand des verknüpften Dateinamens.</summary>
    public async Task<Artwork?> GetArtworkByLinkedFileAsync(string fileName)
    {
        using var db = new AppDbContext();
        return await db.Artworks
            .Include(a => a.Sessions)
            .FirstOrDefaultAsync(a => a.LinkedFileName == fileName && !a.IsArchived);
    }

    /// <summary>
    /// Wird vom ProcessWatcher aufgerufen: sucht zuerst nach LinkedFileName,
    /// dann nach Name, oder legt ein neues Kunstwerk an.
    /// </summary>
    public async Task<Artwork> GetOrCreateByFileNameAsync(string fileName)
    {
        // 1. Exakter Match auf LinkedFileName
        var byLink = await GetArtworkByLinkedFileAsync(fileName);
        if (byLink != null) return byLink;

        // 2. Fallback: Match auf Name (für Rückwärtskompatibilität)
        using var db = new AppDbContext();
        var byName = await db.Artworks
            .Include(a => a.Sessions)
            .FirstOrDefaultAsync(a => a.Name == fileName && !a.IsArchived);
        if (byName != null)
        {
            // Verknüpfung automatisch setzen
            byName.LinkedFileName = fileName;
            db.Artworks.Update(byName);
            await db.SaveChangesAsync();
            return byName;
        }

        // 3. Neu anlegen mit Verknüpfung
        return await AddArtworkAsync(fileName, linkedFileName: fileName);
    }

    /// <summary>Manuell ein Kunstwerk anlegen (optional mit verknüpfter Datei).</summary>
    public async Task<Artwork> AddArtworkAsync(string name, string? linkedFileName = null)
    {
        using var db = new AppDbContext();
        var artwork = new Artwork
        {
            Name = name,
            LinkedFileName = linkedFileName,
            CreatedAt = DateTime.Now
        };
        db.Artworks.Add(artwork);
        await db.SaveChangesAsync();
        return artwork;
    }

    /// <summary>Verknüpfte Datei ändern (Relink wie in InDesign).</summary>
    public async Task RelinkArtworkAsync(int artworkId, string? newLinkedFileName)
    {
        using var db = new AppDbContext();
        var artwork = await db.Artworks.FindAsync(artworkId);
        if (artwork != null)
        {
            artwork.LinkedFileName = newLinkedFileName;
            await db.SaveChangesAsync();
        }
    }

    public async Task UpdateArtworkAsync(Artwork artwork)
    {
        using var db = new AppDbContext();
        db.Artworks.Update(artwork);
        await db.SaveChangesAsync();
    }

    public async Task DeleteArtworkAsync(int artworkId)
    {
        using var db = new AppDbContext();
        var artwork = await db.Artworks.FindAsync(artworkId);
        if (artwork != null)
        {
            db.Artworks.Remove(artwork);
            await db.SaveChangesAsync();
        }
    }

    public async Task<TrackingSession> AddSessionAsync(int artworkId, DateTime start, DateTime end)
    {
        using var db = new AppDbContext();
        var session = new TrackingSession
        {
            ArtworkId = artworkId,
            StartTime = start,
            EndTime = end
        };
        db.Sessions.Add(session);
        await db.SaveChangesAsync();
        return session;
    }

    public async Task DeleteSessionAsync(int sessionId)
    {
        using var db = new AppDbContext();
        var session = await db.Sessions.FindAsync(sessionId);
        if (session != null)
        {
            db.Sessions.Remove(session);
            await db.SaveChangesAsync();
        }
    }

    /// <summary>
    /// Verschiebt alle Sessions von sourceId nach targetId und löscht das Quell-Kunstwerk.
    /// </summary>
    public async Task MergeArtworksAsync(int targetId, int sourceId)
    {
        using var db = new AppDbContext();
        var sessions = await db.Sessions.Where(s => s.ArtworkId == sourceId).ToListAsync();
        foreach (var s in sessions)
            s.ArtworkId = targetId;

        var source = await db.Artworks.FindAsync(sourceId);
        if (source != null)
            db.Artworks.Remove(source);

        await db.SaveChangesAsync();
    }

    public async Task<List<TrackingSession>> GetSessionsForArtworkAsync(int artworkId)
    {
        using var db = new AppDbContext();
        return await db.Sessions
            .Where(s => s.ArtworkId == artworkId)
            .OrderByDescending(s => s.StartTime)
            .ToListAsync();
    }

    public async Task<List<TrackingSession>> GetAllSessionsAsync(int days = 30)
    {
        using var db = new AppDbContext();
        var since = DateTime.Now.AddDays(-days);
        return await db.Sessions
            .Include(s => s.Artwork)
            .Where(s => s.StartTime >= since)
            .OrderByDescending(s => s.StartTime)
            .ToListAsync();
    }
}
